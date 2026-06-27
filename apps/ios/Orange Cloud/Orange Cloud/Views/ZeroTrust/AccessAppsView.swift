//
//  AccessAppsView.swift
//  Orange Cloud
//
//  Zero Trust Access 应用（只读列表）。account 级，access.read。
//

import SwiftUI

struct AccessAppsView: View {

    let session: SessionStore

    @State private var vm: AccessAppsViewModel?

    var body: some View {
        Group {
            if let vm {
                content(vm)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background { SkyBackground() }
        .navigationTitle("Access 应用")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await session.ensureAccounts()
            guard vm == nil else { return }
            let model = AccessAppsViewModel(service: session.zeroTrustService, accountId: session.selectedAccount?.id)
            vm = model
            await model.load()
        }
    }

    @ViewBuilder
    private func content(_ vm: AccessAppsViewModel) -> some View {
        if vm.isLoading && !vm.loaded {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.apps.isEmpty {
            ContentUnavailableView {
                Label("没有 Access 应用", systemImage: "lock.shield")
            } description: {
                Text(vm.error ?? String(localized: "该账号下还没有受 Access 保护的应用。"))
            }
        } else {
            List {
                Section {
                    ForEach(vm.apps) { app in
                        HStack(spacing: 12) {
                            TintIcon(systemImage: "lock.shield", color: .ocOrange)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(app.name?.isEmpty == false ? app.name! : (app.domain ?? "—"))
                                    .font(.callout)
                                    .lineLimit(1)
                                if let domain = app.domain, !domain.isEmpty {
                                    Text(domain)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer(minLength: 8)
                            Text(app.typeLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.secondary.opacity(0.12), in: Capsule())
                        }
                        .padding(.vertical, 2)
                    }
                } footer: {
                    Text("受 Cloudflare Access 保护的应用（只读）。")
                }
                .glassRow()
            }
            .daybreakList()
            .refreshable { await vm.load() }
        }
    }
}
