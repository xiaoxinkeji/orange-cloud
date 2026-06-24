//
//  CacheRulesView.swift
//  Orange Cloud
//
//  Cache Rules 列表：精细化缓存策略。
//

import SwiftUI

struct CacheRulesView: View {

    let zoneId: String
    let zoneName: String
    let session: SessionStore

    @Environment(AuthManager.self) private var auth

    @State private var rules: [CacheRule] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading && rules.isEmpty {
                SkeletonList(rows: 6, trailing: true)
            } else if rules.isEmpty {
                emptyState
            } else {
                rulesList
            }
        }
        .background { SkyBackground() }
        .navigationTitle("Cache Rules")
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
            ForEach(rules) { rule in
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

    private func ruleRow(_ rule: CacheRule) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                cachePill(rule.actionParameters?.cache)
                Spacer()
                if let enabled = rule.enabled {
                    enabledBadge(enabled)
                }
            }

            ttlSection(rule.actionParameters)

            if let expr = rule.expression, !expr.isEmpty {
                Text(expr)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

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
    private func ttlSection(_ params: CacheRuleParams?) -> some View {
        if let edge = params?.edgeTTL {
            HStack(spacing: 6) {
                ttlPill(String(localized: "Edge"), value: edge.defaultLabel, color: .blue)
                Text(edge.modeLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let statusTTLs = edge.statusCodeTTL, !statusTTLs.isEmpty {
                    ForEach(statusTTLs, id: \.statusCode) { sttl in
                        Text(sttl.label)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.blue.opacity(0.8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.blue.opacity(0.06), in: Capsule())
                    }
                }
            }
        }
        if let browser = params?.browserTTL {
            HStack(spacing: 6) {
                ttlPill(String(localized: "Browser"), value: browser.defaultLabel, color: .purple)
                Text(browser.modeLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func ttlPill(_ label: String, value: String?, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
            if let v = value {
                Text(v)
                    .font(.caption2.weight(.medium).monospacedDigit())
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, 5)
        .padding(.vertical, 1)
        .background(color.opacity(0.1), in: Capsule())
    }

    private func cachePill(_ cache: Bool?) -> some View {
        let color: Color = (cache == false) ? .orange : .green
        let text: String = (cache == false)
            ? String(localized: "绕过缓存")
            : String(localized: "启用缓存")
        return Text(text)
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
            "暂无 Cache Rules",
            systemImage: "clock.arrow.circlepath",
            description: Text("\(zoneName) 尚未配置 Cache Rules。\n前往 dash.cloudflare.com → Caching → Cache Rules 创建。")
        )
    }

    private func load() async {
        isLoading = true
        error = nil
        do {
            rules = try await session.cacheRuleService.listRules(zoneId: zoneId)
        } catch {
            self.error = error.localizedDescription
            rules = []
        }
        isLoading = false
    }
}
