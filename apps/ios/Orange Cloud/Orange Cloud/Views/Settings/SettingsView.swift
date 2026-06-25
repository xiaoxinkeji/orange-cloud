//
//  SettingsView.swift
//  Orange Cloud
//
//  设置根页：已登录的 Cloudflare 账号（多身份）、通知、关于。
//  退出登录在各账号详情页内；全部退出后自动回到登录页。
//

import SwiftUI

struct SettingsView: View {

    @Environment(AuthManager.self) private var auth
    @Environment(SessionStore.self) private var session
    @Environment(\.openURL) private var openURL

    @State private var showAddAccount = false
    @State private var showTokenEntry = false
    @State private var iCloudSync = UserDefaults.standard.bool(forKey: AuthManager.iCloudSyncKey)

    /// 「今日」用量的日界口径（App Group，与 Widget 共享），默认 UTC
    @AppStorage(DayBoundary.storageKey, store: UserDefaults(suiteName: WidgetSnapshot.appGroupID))
    private var dayBoundaryRaw = DayBoundary.utc.rawValue

    @AppStorage(AppAppearance.storageKey) private var appearanceRaw = AppAppearance.system.rawValue
    @AppStorage(AppLanguage.storageKey)   private var languageRaw   = AppLanguage.system.rawValue

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                // ── Cloudflare 账号（登录身份）──
                Section {
                    ForEach(auth.sessions) { identity in
                        NavigationLink {
                            IdentityDetailView(identity: identity)
                        } label: {
                            identityRow(identity)
                        }
                    }

                    Button {
                        showAddAccount = true
                    } label: {
                        HStack(spacing: 12) {
                            TintIcon(systemImage: "plus", color: .ocOrange, size: 38)
                            Text("添加账号")
                                .foregroundStyle(Color.ocOrange)
                        }
                        .padding(.vertical, 2)
                    }
                    Button {
                        showTokenEntry = true
                    } label: {
                        HStack(spacing: 12) {
                            TintIcon(systemImage: "key", color: .blue, size: 38)
                            Text("使用 API Token")
                                .foregroundStyle(.blue)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Cloudflare 账号")
                } footer: {
                    Text("每个账号独立登录授权。点击账号查看权限与退出登录。")
                }
                .glassRow()

                // ── 同步 ──
                Section {
                    Toggle(isOn: $iCloudSync) {
                        HStack(spacing: 12) {
                            TintIcon(systemImage: "icloud", color: .blue)
                            Text("iCloud 同步")
                        }
                    }
                } header: {
                    Text("同步")
                } footer: {
                    Text("开启后：登录身份经 iCloud 钥匙串在你的设备间同步（端到端加密），账单日与套餐预设等偏好经 iCloud 同步。关闭将把登录信息从 iCloud 移除，仅保留本机。")
                }
                .onChange(of: iCloudSync) {
                    auth.setICloudSync(iCloudSync)
                    AccountPrefsStore.shared.applySyncChange(iCloudSync)
                }
                .glassRow()

                // ── 用量口径 ──
                Section {
                    Picker(selection: $dayBoundaryRaw) {
                        ForEach(DayBoundary.allCases) { boundary in
                            Text(boundary.label).tag(boundary.rawValue)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            TintIcon(systemImage: "clock", color: .ocOrange)
                            Text("「今日」按")
                        }
                    }
                } header: {
                    Text("用量")
                } footer: {
                    Text("决定用量统计里「今日」从哪个零点起算。Cloudflare 免费额度按 UTC 重置，选「本地时间」只改变 App 的统计窗口，不改变额度重置时刻；D1/KV 受接口按 UTC 天聚合的限制，始终按 UTC 统计。")
                }
                .glassRow()

                // ── 外观与语言 ──
                Section {
                    Picker(selection: $appearanceRaw) {
                        ForEach(AppAppearance.allCases) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            TintIcon(systemImage: "circle.lefthalf.filled", color: .indigo)
                            Text("外观")
                        }
                    }

                    Picker(selection: $languageRaw) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.label).tag(language.rawValue)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            TintIcon(systemImage: "character.bubble", color: .teal)
                            Text("语言")
                        }
                    }
                } header: {
                    Text("外观与语言")
                } footer: {
                    Text("语言默认跟随系统。更改语言后需重新打开 App 生效。")
                }
                .onChange(of: languageRaw) {
                    (AppLanguage(rawValue: languageRaw) ?? .system).apply()
                }
                .glassRow()

                // ── 通知 ──
                NotificationSettingsSection()

                // ── 服务状态 ──
                Section {
                    NavigationLink {
                        CloudflareStatusView()
                    } label: {
                        HStack(spacing: 12) {
                            TintIcon(systemImage: "waveform.path.ecg", color: .green)
                            Text("Cloudflare 状态")
                        }
                    }
                } header: {
                    Text("服务状态")
                } footer: {
                    Text("来自 cloudflarestatus.com 的官方服务状态与事件。")
                }
                .glassRow()

                // ── 关于 ──
                Section {
                    HStack(spacing: 12) {
                        TintIcon(systemImage: "info", color: .blue)
                        Text("版本")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                    updateCheckRow
                    aboutLink("隐私政策", icon: "doc.text", url: OAuthConfig.privacyPolicyURL)
                    aboutLink("使用条款", icon: "doc.plaintext", url: OAuthConfig.termsOfUseURL)
                } header: {
                    Text("关于")
                } footer: {
                    Text("Orange Cloud · 第三方 Cloudflare 客户端")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
                .glassRow()
            }
            .daybreakList()
            .navigationTitle("设置")
            .task {
                await session.ensureAccounts()
                updateResult = await UpdateService.checkForUpdate()
            }
            .sheet(isPresented: $showAddAccount) {
                AddAccountSheet()
            }
            .sheet(isPresented: $showTokenEntry) {
                TokenEntryView()
            }
        }
    }

    // MARK: - 更新检测

    @State private var updateResult: UpdateService.UpdateResult = .unknown

    @ViewBuilder
    private var updateCheckRow: some View {
        Button {
            if case .updateAvailable(_, let url) = updateResult,
               let downloadURL = URL(string: url) {
                openURL(downloadURL)
            } else {
                Task {
                    updateResult = .unknown
                    updateResult = await UpdateService.checkForUpdate()
                }
            }
        } label: {
            HStack(spacing: 12) {
                TintIcon(
                    systemImage: {
                        switch updateResult {
                        case .updateAvailable: return "arrow.down.circle.fill"
                        default:               return "arrow.down.circle"
                        }
                    }(),
                    color: {
                        switch updateResult {
                        case .updateAvailable: return .orange
                        default:               return .green
                        }
                    }()
                )
                Text({
                    switch updateResult {
                    case .updateAvailable: return "下载新版本"
                    default:               return "检查更新"
                    }
                }())
                    .foregroundStyle(.primary)
                Spacer()
                switch updateResult {
                case .unknown:
                    Text("点击检查")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                case .upToDate:
                    Text("已是最新")
                        .font(.caption)
                        .foregroundStyle(.green)
                case .updateAvailable(let version, _):
                    Text(version)
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.orange)
                case .error(let msg):
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 身份行

    private func identityRow(_ identity: AuthSessionMeta) -> some View {
        HStack(spacing: 12) {
            Text(String(identity.label.first ?? "C").uppercased())
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(
                    LinearGradient(
                        colors: [Color(red: 1, green: 0.65, blue: 0.31), .ocOrangePressed],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(identity.label)
                        .font(.body)
                        .lineLimit(1)
                    if identity.authType == .apiToken {
                        Image(systemName: "key.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
                if identity.authType == .apiToken {
                    Text("全权限")
                        .font(.caption)
                        .foregroundStyle(.blue)
                } else {
                    Text("\(identity.scopes.count) 项权限")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if auth.currentSessionId == identity.id {
                Text("当前")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.ocOrange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.ocOrange.opacity(0.14), in: Capsule())
            }
        }
        .padding(.vertical, 2)
    }

    private func aboutLink(_ title: String, icon: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                TintIcon(systemImage: icon, color: .gray)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - 添加账号（新 OAuth 登录，不影响现有身份）

private struct AddAccountSheet: View {

    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PermissionSelectionView(freshLogin: true)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { dismiss() }
                    }
                }
        }
        // 登录成功 → currentSessionId 切到新身份 → 关闭弹层
        .onChange(of: auth.currentSessionId) {
            dismiss()
        }
        .interactiveDismissDisabled(auth.isLoading)
    }
}

// MARK: - 通知（主开关授权后再展开子开关）

private struct NotificationSettingsSection: View {

    @AppStorage(AppNotifications.masterKey) private var notificationsEnabled = false
    @AppStorage("notifyZoneStatus")   private var notifyZoneStatus = true
    @AppStorage("notifyWorkerErrors") private var notifyWorkerErrors = true

    @State private var systemDenied = false
    @State private var isRequesting = false

    var body: some View {
        Section {
            Toggle(isOn: $notificationsEnabled) {
                HStack(spacing: 12) {
                    TintIcon(systemImage: "bell.badge", color: .ocOrange)
                    Text("允许通知")
                    if isRequesting {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isRequesting)

            if systemDenied {
                Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                    HStack(spacing: 12) {
                        TintIcon(systemImage: "gear", color: .gray)
                        Text("前往系统设置开启通知权限")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            if notificationsEnabled && !systemDenied {
                Toggle(isOn: $notifyZoneStatus) {
                    HStack(spacing: 12) {
                        TintIcon(systemImage: "globe", color: .ocOrange)
                        Text("域名状态变更")
                    }
                }
                Toggle(isOn: $notifyWorkerErrors) {
                    HStack(spacing: 12) {
                        TintIcon(systemImage: "exclamationmark.triangle", color: .red)
                        Text("Worker 错误通知")
                    }
                }
            }
        } header: {
            Text("通知")
        } footer: {
            Text(notificationsEnabled && !systemDenied
                 ? String(localized: "通过系统后台刷新检测变化后发送本地通知。时机由 iOS 调度，可能有数分钟至数小时延迟。")
                 : String(localized: "开启后在 Zone 状态变化或 Workers 出错时收到提醒。"))
        }
        .onChange(of: notificationsEnabled) {
            guard notificationsEnabled else { return }
            Task {
                isRequesting = true
                let granted = await AppNotifications.requestAuthorization()
                isRequesting = false
                if granted {
                    systemDenied = false
                } else {
                    systemDenied = true
                    notificationsEnabled = false
                }
            }
        }
        .task {
            // 系统层被拒时同步关闭主开关
            let status = await AppNotifications.authorizationStatus()
            systemDenied = (status == .denied)
            if systemDenied {
                notificationsEnabled = false
            }
        }
        .glassRow()
    }
}
