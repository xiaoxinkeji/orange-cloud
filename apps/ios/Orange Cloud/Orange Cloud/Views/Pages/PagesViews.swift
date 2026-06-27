//
//  PagesViews.swift
//  Orange Cloud
//
//  Cloudflare Pages 项目列表与详情。
//

import SwiftUI

@MainActor
struct PagesListView: View {

    @Environment(SessionStore.self) private var session
    @Environment(AuthManager.self) private var auth

    @State private var projects: [PagesProject] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var searchText = ""

    private var needsAPIToken: Bool {
        auth.hasAPITokenAvailable && !auth.isAPIToken
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && projects.isEmpty {
                    SkeletonList(rows: 6, trailing: true)
                } else if projects.isEmpty {
                    emptyState
                } else if filteredProjects.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    projectList
                }
            }
            .background { SkyBackground() }
            .navigationTitle("Pages")
            .searchable(text: $searchText, prompt: "搜索项目")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("刷新", systemImage: "arrow.clockwise") {
                        Task { await load() }
                    }
                    .symbolEffect(.rotate, isActive: isLoading)
                }
            }
            .task { await load() }
            .alert("加载失败", isPresented: .init(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("好", role: .cancel) {}
                if needsAPIToken {
                    Button("切换到 API Token") {
                        switchToAPIToken()
                    }
                }
            } message: {
                if needsAPIToken {
                    Text("\(error ?? "")\n\n当前使用 OAuth 身份，部分 API 需要 API Token。已有可用 API Token，建议切换后重试。")
                } else {
                    Text(error ?? "")
                }
            }
            .navigationDestination(for: PagesProject.self) { project in
                PagesDetailView(project: project)
            }
        }
    }

    private func switchToAPIToken() {
        guard let tokenSession = auth.sessions.first(where: { $0.authType == .apiToken }) else { return }
        auth.switchSession(tokenSession.id)
        error = nil
        Task { await load() }
    }

    private var filteredProjects: [PagesProject] {
        guard !searchText.isEmpty else { return projects }
        return projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var projectList: some View {
        List {
            ForEach(filteredProjects) { project in
                NavigationLink(value: project) {
                    PagesRowView(project: project)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .padding(.vertical, 4)
                )
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
        }
        .daybreakList()
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "暂无 Pages 项目",
            systemImage: "doc.richtext",
            description: Text("此账号下没有 Cloudflare Pages 项目。\n前往 dash.cloudflare.com 创建第一个项目。")
        )
    }

    private func load() async {
        guard let accountId = session.selectedAccount?.id else {
            error = String(localized: "未选择账号")
            return
        }
        isLoading = true
        error = nil
        do {
            projects = try await session.pagesService.listProjects(accountId: accountId)
        } catch {
            self.error = error.localizedDescription
            projects = []
        }
        isLoading = false
    }
}

struct PagesRowView: View {

    let project: PagesProject

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.richtext.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(.blue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.headline)
                    .lineLimit(1)

                if let subdomain = project.subdomain {
                    Text("\(subdomain).pages.dev")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let deploy = project.latestDeployment {
                    HStack(spacing: 4) {
                        deploymentStageBadge(deploy.latestStage?.status ?? "unknown")
                        if let date = PagesProject.parseDate(deploy.modifiedOn ?? deploy.createdOn) {
                            Text("·")
                                .foregroundStyle(.tertiary)
                            Text(date, format: .relative(presentation: .named))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func deploymentStageBadge(_ stage: String) -> some View {
        let color: Color = {
            switch stage {
            case "deploying", "initialize":     return .orange
            case "active", "success":           return .green
            case "build_failed", "error":       return .red
            case "canceled":                    return .gray
            default:                            return .secondary
            }
        }()
        return Text(stage)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }
}

@MainActor
struct PagesDetailView: View {

    let project: PagesProject

    @Environment(SessionStore.self) private var session

    @State private var fullProject: PagesProject?
    @State private var deployments: [PagesDeployment] = []
    @State private var domains: [PagesDomain] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        List {
            infoSection
            deploymentSection
            domainsSection
        }
        .daybreakList()
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .alert("加载失败", isPresented: .init(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(error ?? "")
        }
    }

    private var infoSection: some View {
        Section("项目信息") {
            if let subdomain = fullProject?.subdomain ?? project.subdomain {
                LabeledContent("Pages 域名", value: "\(subdomain).pages.dev")
            }

            if let source = fullProject?.source ?? project.source {
                if let owner = source.config?.owner, let repo = source.config?.repoName {
                    LabeledContent("仓库") {
                        Text("\(owner)/\(repo)")
                            .monospacedDigit()
                    }
                }
                if let branch = source.config?.productionBranch {
                    LabeledContent("分支", value: branch)
                }
            }

            if let build = fullProject?.buildConfig ?? project.buildConfig {
                if let cmd = build.buildCommand {
                    LabeledContent("构建命令", value: cmd)
                }
                if let dir = build.destinationDir {
                    LabeledContent("输出目录", value: dir)
                }
            }

            if let created = PagesProject.parseDate(project.createdOn) {
                LabeledContent("创建时间") {
                    Text(created, format: .dateTime.year().month().day())
                }
            }
        }
        .glassRow()
    }

    private var deploymentSection: some View {
        Section("部署") {
            if deployments.isEmpty && !isLoading {
                Text("暂无部署记录")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if isLoading && deployments.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonBlock(height: 44, cornerRadius: 8)
                }
            } else {
                ForEach(deployments) { deployment in
                    deploymentRow(deployment)
                }
            }
        }
        .glassRow()
    }

    private func deploymentRow(_ deployment: PagesDeployment) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(deployment.shortId ?? String(deployment.id.prefix(7)))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()

                Spacer()

                deploymentStageBadge(deployment.latestStage?.status ?? "unknown")
            }

            if let meta = deployment.deploymentTrigger?.metadata, let msg = meta.commitMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                if let env = deployment.environment {
                    environmentBadge(env)
                }

                if let date = PagesDeployment.parseDate(deployment.createdOn) {
                    Text(date, format: .relative(presentation: .named))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var domainsSection: some View {
        Group {
            if !domains.isEmpty {
                Section("自定义域名") {
                    ForEach(domains) { domain in
                        HStack {
                            Text(domain.name)
                                .font(.subheadline)
                            Spacer()
                            if let status = domain.status {
                                domainStatusBadge(status)
                            }
                        }
                    }
                }
                .glassRow()
            }
        }
    }

    private func deploymentStageBadge(_ stage: String) -> some View {
        let color: Color = {
            switch stage {
            case "deploying", "initialize":     return .orange
            case "active", "success":           return .green
            case "build_failed", "error":       return .red
            case "canceled":                    return .gray
            default:                            return .secondary
            }
        }()
        return Text(stage)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }

    private func environmentBadge(_ env: String) -> some View {
        Text(env == "production" ? "Production" : "Preview")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(env == "production" ? .green : .blue)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                (env == "production" ? Color.green : Color.blue).opacity(0.12),
                in: Capsule()
            )
    }

    private func domainStatusBadge(_ status: String) -> some View {
        let color: Color = status == "active" ? .green : .orange
        return Text(status)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }

    private func load() async {
        guard let accountId = session.selectedAccount?.id else {
            error = String(localized: "未选择账号")
            return
        }
        isLoading = true
        error = nil
        do {
            async let projectTask = session.pagesService.getProject(
                accountId: accountId, projectName: project.name
            )
            async let deploymentsTask = session.pagesService.listDeployments(
                accountId: accountId, projectName: project.name
            )
            async let domainsTask = session.pagesService.listDomains(
                accountId: accountId, projectName: project.name
            )

            fullProject = try await projectTask
            deployments = (try? await deploymentsTask) ?? []
            domains = (try? await domainsTask) ?? []
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
