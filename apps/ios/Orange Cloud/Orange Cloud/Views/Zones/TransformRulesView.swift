//
//  TransformRulesView.swift
//  Orange Cloud
//
//  Transform Rules 列表：URL 改写、请求头修改、响应头修改。
//

import SwiftUI

struct TransformRulesView: View {

    let zoneId: String
    let zoneName: String
    let session: SessionStore

    @Environment(AuthManager.self) private var auth

    @State private var rules: [TransformRule] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var searchText = ""

    private var filteredRules: [TransformRule] {
        if searchText.isEmpty { return rules }
        return rules.filter { rule in
            rule.expression?.localizedCaseInsensitiveContains(searchText) == true ||
            rule.description?.localizedCaseInsensitiveContains(searchText) == true ||
            rule.actionLabel.localizedCaseInsensitiveContains(searchText)
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
        .searchable(text: $searchText, prompt: "搜索规则")
        .navigationTitle("Transform Rules")
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

    private func ruleRow(_ rule: TransformRule) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                actionBadge(rule.actionLabel)
                Spacer()
                if let enabled = rule.enabled {
                    enabledBadge(enabled)
                }
            }

            if let expr = rule.expression, !expr.isEmpty {
                Text(expr)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            ruleDetail(rule)

            if let desc = rule.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func ruleDetail(_ rule: TransformRule) -> some View {
        if rule.isURLRewrite, let uri = rule.actionParameters?.uri {
            VStack(alignment: .leading, spacing: 2) {
                if let pathVal = uri.path?.value {
                    HStack(spacing: 4) {
                        Text("path:")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text(pathVal)
                            .font(.caption.monospaced())
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                } else if let pathExpr = uri.path?.expression {
                    HStack(spacing: 4) {
                        Text("path:")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text(pathExpr)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                if let queryVal = uri.query?.value {
                    HStack(spacing: 4) {
                        Text("query:")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text(queryVal)
                            .font(.caption.monospaced())
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                } else if let queryExpr = uri.query?.expression {
                    HStack(spacing: 4) {
                        Text("query:")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text(queryExpr)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(.top, 2)
        }

        if (rule.isRequestHeader || rule.isResponseHeader),
           let headers = rule.actionParameters?.headers, !headers.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(headers.keys.sorted()), id: \.self) { key in
                    if let op = headers[key] {
                        HStack(spacing: 4) {
                            Text(key)
                                .font(.caption.monospaced())
                                .foregroundStyle(.primary)
                            Text(op.opLabel)
                                .font(.caption2)
                                .foregroundStyle(op.operation == "set" ? .green : .orange)
                            if let val = op.value {
                                Text(val)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .padding(.top, 2)
        }
    }

    private func actionBadge(_ label: String) -> some View {
        let color: Color = {
            switch label {
            case String(localized: "URL 改写"): return .blue
            case String(localized: "请求头"):   return .purple
            case String(localized: "响应头"):   return .orange
            default:                            return .secondary
            }
        }()
        return Text(label)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
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
            "暂无 Transform Rules",
            systemImage: "arrow.triangle.pull",
            description: Text("\(zoneName) 尚未配置 URL 改写或请求/响应头修改规则。\n前往 dash.cloudflare.com → Rules → Transform Rules 创建。")
        )
    }

    private func load() async {
        isLoading = true
        error = nil
        do {
            rules = try await session.transformRuleService.listRules(zoneId: zoneId)
        } catch {
            self.error = error.localizedDescription
            rules = []
        }
        isLoading = false
    }
}
