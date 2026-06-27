//
//  P3Views.swift
//  Orange Cloud
//
//  P3 功能视图：IP 访问规则列表、Bulk Redirects 列表。
//

import SwiftUI

struct IPRulesListView: View {

    let zoneId: String
    let zoneName: String
    let session: SessionStore

    @Environment(AuthManager.self) private var auth

    @State private var rules: [FirewallAccessRule] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var searchText = ""

    private var filteredRules: [FirewallAccessRule] {
        if searchText.isEmpty { return rules }
        return rules.filter { rule in
            (rule.configuration?.value?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (rule.mode?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (rule.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        Group {
            if isLoading && rules.isEmpty {
                SkeletonList(rows: 6, trailing: true)
            } else if !searchText.isEmpty && filteredRules.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if rules.isEmpty {
                emptyState
            } else {
                rulesList
            }
        }
        .background { SkyBackground() }
        .searchable(text: $searchText, prompt: "搜索 IP 或备注")
        .navigationTitle("IP 访问规则")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("刷新", systemImage: "arrow.clockwise") {
                    Task { await load() }
                }
            }
        }
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

    private var rulesList: some View {
        List {
            ForEach(filteredRules) { rule in
                ruleRow(rule)
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

    private func ruleRow(_ rule: FirewallAccessRule) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(rule.configuration?.value ?? "—")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
                Spacer()
                modeBadge(rule.mode ?? "")
            }

            HStack(spacing: 6) {
                Text(rule.configuration?.targetLabel ?? "—")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(.secondary.opacity(0.1), in: Capsule())

                if let notes = rule.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func modeBadge(_ mode: String) -> some View {
        let color: Color = {
            switch mode {
            case "block":                        return .red
            case "challenge", "js_challenge",
                 "managed_challenge":            return .orange
            case "whitelist":                    return .green
            default:                             return .secondary
            }
        }()
        return Text(FirewallAccessRule.modeLabel(mode))
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "暂无 IP 访问规则",
            systemImage: "hand.raised",
            description: Text("\(zoneName) 尚未配置任何 IP/ASN/国家级的访问规则。\n前往 dash.cloudflare.com 创建。")
        )
    }

    private func load() async {
        isLoading = true
        error = nil
        do {
            rules = try await session.firewallAccessRuleService.rules(zoneId: zoneId)
        } catch {
            self.error = error.localizedDescription
            rules = []
        }
        isLoading = false
    }
}

struct BulkRedirectsView: View {

    let zoneId: String
    let zoneName: String
    let session: SessionStore

    @Environment(AuthManager.self) private var auth

    @State private var rules: [BulkRedirectRule] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var searchText = ""

    private var filteredRules: [BulkRedirectRule] {
        if searchText.isEmpty { return rules }
        return rules.filter { rule in
            (rule.actionParameters?.fromValue?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (rule.actionParameters?.toValue?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (rule.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        Group {
            if isLoading && rules.isEmpty {
                SkeletonList(rows: 6, trailing: true)
            } else if !searchText.isEmpty && filteredRules.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if rules.isEmpty {
                emptyState
            } else {
                rulesList
            }
        }
        .background { SkyBackground() }
        .searchable(text: $searchText, prompt: "搜索 URL")
        .navigationTitle("URL 转发")
        .navigationBarTitleDisplayMode(.inline)
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
        } message: {
            Text(error ?? "")
        }
    }

    private var rulesList: some View {
        List {
            ForEach(filteredRules) { rule in
                redirectRow(rule)
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

    private func redirectRow(_ rule: BulkRedirectRule) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let from = rule.actionParameters?.fromValue {
                HStack {
                    Image(systemName: "arrow.forward")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(from)
                        .font(.subheadline.monospaced())
                        .lineLimit(1)
                    Spacer()
                    if let enabled = rule.enabled {
                        enabledBadge(enabled)
                    }
                }
            }

            if let to = rule.actionParameters?.toValue {
                HStack {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(to)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.leading, 4)
            }

            HStack(spacing: 6) {
                if let code = rule.actionParameters {
                    Text(code.statusLabel)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.blue.opacity(0.1), in: Capsule())
                }

                if let desc = rule.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func enabledBadge(_ enabled: Bool) -> some View {
        Text(enabled ? String(localized: "启用") : String(localized: "禁用"))
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(enabled ? .green : .secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background((enabled ? Color.green : Color.secondary).opacity(0.12), in: Capsule())
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "暂无转发规则",
            systemImage: "arrow.triangle.swap",
            description: Text("\(zoneName) 尚未配置 Bulk Redirect 规则。\n前往 dash.cloudflare.com → Rules → Bulk Redirects 创建。")
        )
    }

    private func load() async {
        isLoading = true
        error = nil
        do {
            guard let accountId = session.selectedAccount?.id else {
                error = String(localized: "未选择账号")
                isLoading = false
                return
            }
            rules = try await session.bulkRedirectService.listRedirects(accountId: accountId)
        } catch {
            self.error = error.localizedDescription
            rules = []
        }
        isLoading = false
    }
}
