//
//  PagesDomainsView.swift
//  Orange Cloud
//
//  Pages 项目自定义域名管理：列表、添加、删除。
//

import SwiftUI

struct PagesDomainsView: View {

    let accountId: String
    let projectName: String
    let session: SessionStore

    @Environment(AuthManager.self) private var auth
    @State private var domains: [PagesDomain] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showAdd = false
    @State private var newDomain = ""
    @State private var isAdding = false
    @State private var addError: String?
    @State private var deleteTarget: PagesDomain?
    @State private var isDeleting = false

    private var canWrite: Bool { auth.hasScope("page.write") }

    var body: some View {
        Group {
            if isLoading {
                SkeletonList(rows: 4, trailing: false)
            } else if domains.isEmpty {
                ContentUnavailableView {
                    Label("没有自定义域名", systemImage: "globe")
                } description: {
                    Text("为 Pages 项目绑定自定义域名后，即可通过自己的域名访问。")
                } actions: {
                    if canWrite {
                        Button("添加域名") { showAdd = true }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.ocOrangePressed)
                            .fontWeight(.bold)
                    }
                }
            } else {
                List {
                    Section {
                        ForEach(domains) { domain in
                            domainRow(domain)
                        }
                        .onDelete { indexSet in
                            if canWrite {
                                for index in indexSet {
                                    deleteTarget = domains[index]
                                }
                            }
                        }
                    } footer: {
                        Text("左滑删除域名。添加自定义域名前，请先在域名 DNS 中添加对应的 CNAME 记录指向 pages.dev 地址。")
                    }
                    .glassRow()
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background { SkyBackground() }
        .navigationTitle("自定义域名")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if canWrite {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("添加", systemImage: "plus") { showAdd = true }
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .alert("添加域名", isPresented: $showAdd) {
            TextField("例如：www.example.com", text: $newDomain)
                .autocorrectionDisabled()
                #if os(iOS)
                .autocapitalization(.none)
                .keyboardType(.URL)
                #endif
            Button("取消", role: .cancel) {
                newDomain = ""
                addError = nil
            }
            Button("添加") {
                Task { await add() }
            }
            .disabled(newDomain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAdding)
        } message: {
            if let addError {
                Text(addError).foregroundStyle(.red)
            } else {
                Text("请在 DNS 中添加一条 CNAME 记录指向该 Pages 项目的 \\(projectName).pages.dev，然后在此输入域名。")
            }
        }
        .alert("删除域名？", isPresented: .init(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        )) {
            Button("删除", role: .destructive) {
                if let target = deleteTarget {
                    Task { await delete(target) }
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将从 Pages 项目「\\(projectName)」中移除域名「\\(deleteTarget?.name ?? "")」。此操作不可撤销。")
        }
        .alert("出错了", isPresented: .init(
            get: { error != nil }, set: { if !$0 { error = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(error ?? "")
        }
    }

    @ViewBuilder
    private func domainRow(_ domain: PagesDomain) -> some View {
        HStack(spacing: 12) {
            TintIcon(systemImage: "globe", color: .blue, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(domain.name)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                if let status = domain.status {
                    Text(statusLabel(status))
                        .font(.caption)
                        .foregroundStyle(statusColor(status))
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func statusLabel(_ status: String) -> String {
        switch status.lowercased() {
        case "active":           String(localized: "生效中")
        case "pending":          String(localized: "验证中")
        case "failed":           String(localized: "验证失败")
        default:                 status
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "active":  .green
        case "pending": .orange
        default:        .red
        }
    }

    private func load() async {
        isLoading = true
        error = nil
        do {
            domains = try await session.pagesService.listDomains(accountId: accountId, projectName: projectName)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func add() async {
        let name = newDomain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        isAdding = true
        addError = nil
        do {
            let created = try await session.pagesService.addDomain(accountId: accountId, projectName: projectName, domain: name)
            domains.append(created)
            newDomain = ""
            showAdd = false
        } catch {
            addError = error.localizedDescription
        }
        isAdding = false
    }

    private func delete(_ domain: PagesDomain) async {
        guard !isDeleting else { return }
        isDeleting = true
        error = nil
        do {
            try await session.pagesService.deleteDomain(
                accountId: accountId,
                projectName: projectName,
                domainId: domain.id
            )
            domains.removeAll { $0.id == domain.id }
        } catch {
            self.error = error.localizedDescription
        }
        deleteTarget = nil
        isDeleting = false
    }
}
