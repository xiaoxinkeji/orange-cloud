//
//  GatewayRulesView.swift
//  Orange Cloud
//
//  Zero Trust Gateway 策略（只读列表）。account 级，teams.read。
//

import SwiftUI

struct GatewayRulesView: View {

    let session: SessionStore

    @State private var vm: GatewayRulesViewModel?

    var body: some View {
        Group {
            if let vm {
                content(vm)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background { SkyBackground() }
        .navigationTitle("Gateway 策略")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await session.ensureAccounts()
            guard vm == nil else { return }
            let model = GatewayRulesViewModel(service: session.zeroTrustService, accountId: session.selectedAccount?.id)
            vm = model
            await model.load()
        }
    }

    @ViewBuilder
    private func content(_ vm: GatewayRulesViewModel) -> some View {
        if vm.isLoading && !vm.loaded {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.rules.isEmpty {
            ContentUnavailableView {
                Label("没有 Gateway 策略", systemImage: "shield.lefthalf.filled")
            } description: {
                Text(vm.error ?? String(localized: "该账号下还没有 Gateway（DNS / HTTP / 网络）策略。"))
            }
        } else {
            List {
                Section {
                    ForEach(vm.rules) { rule in
                        HStack(spacing: 12) {
                            TintIcon(systemImage: "shield.lefthalf.filled",
                                     color: rule.isEnabled ? .ocOrange : .gray)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(rule.name?.isEmpty == false ? rule.name! : String(localized: "未命名策略"))
                                    .font(.callout)
                                    .lineLimit(1)
                                Text("\(rule.kindLabel) · \(rule.actionLabel)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 8)
                            if !rule.isEnabled {
                                Text("已停用")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } footer: {
                    Text("Gateway 的 DNS / HTTP / 网络过滤策略（只读），按优先级自上而下匹配。")
                }
                .glassRow()
            }
            .daybreakList()
            .refreshable { await vm.load() }
        }
    }
}
