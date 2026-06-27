//
//  ZoneDetailView.swift
//  Orange Cloud
//
//  单域名中枢（设计稿 zone-detail.jsx）：
//  hero 卡（头像 + 域名 + 状态/套餐 + 24h 流量统计）+ 管理 / 分析 / 操作分组 + 区域 ID。
//

import SwiftUI
import SwiftData

struct ZoneDetailView: View {

    let zone: CachedZone
    let session: SessionStore

    @Environment(AuthManager.self) private var auth
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [CachedDNSRecord]

    // 分析区（内嵌第一层级，ViewModel 由本页持有，下拉刷新共用）
    @State private var analyticsViewModel: ZoneAnalyticsViewModel

    // 操作区
    @State private var actionsViewModel: ZoneActionsViewModel
    @State private var showPurgeConfirm = false
    @State private var showPurgeSheet = false
    @State private var showPurgeDone = false
    @State private var showPurgeURLSheet = false
    @State private var showActionDenied = false
    @State private var deniedScopeHint = ""
    /// 开关类操作先收口到这里，confirmationDialog 确认后才调 API
    @State private var pendingAction: PendingZoneAction?
    @State private var edgeCerts: [EdgeCertificate] = []
    @State private var customCerts: [CustomCertificate] = []
    @State private var universalSSLEnabled = false
    @State private var certsLoaded = false

    init(zone: CachedZone, session: SessionStore) {
        self.zone = zone
        self.session = session
        let zoneId = zone.id
        _records = Query(filter: #Predicate<CachedDNSRecord> { $0.zoneId == zoneId })
        _analyticsViewModel = State(initialValue: ZoneAnalyticsViewModel(
            analyticsService: session.analyticsService, zoneId: zoneId
        ))
        _actionsViewModel = State(initialValue: ZoneActionsViewModel(
            service: session.zoneSettingsService, zoneId: zoneId
        ))
    }

    private var canReadSettings: Bool { auth.hasScope("zone-settings.read") }
    private var canEditSettings: Bool { auth.hasScope("zone-settings.write") }
    private var canPurge: Bool { auth.hasScope("cache.purge") }

    private var statusText: String {
        switch zone.status {
        case "active":                  String(localized: "已启用")
        case "pending", "initializing": String(localized: "待激活")
        default:                        String(localized: "已暂停")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                heroCard

                // 分析：图表直接内嵌第一层级，置于管理之前
                VStack(alignment: .leading, spacing: 8) {
                    Text("分析")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 4)
                    if auth.hasScope("analytics.read") {
                        ZoneAnalyticsSection(viewModel: analyticsViewModel)
                    } else {
                        Label("需要「流量分析」权限才能展示流量图表", systemImage: "lock")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                            .glassIsland(cornerRadius: OCLayout.chipRadius)
                    }
                }

                sectionCard(String(localized: "管理")) {
                    PermissionGatedNavigationLink(
                        label: String(localized: "DNS 记录"),
                        systemImage: "network",
                        requiredScope: "dns.read",
                        showsChevron: true
                    ) {
                        DNSListView(zoneId: zone.id, zoneName: zone.name, session: session)
                    }
                    .listRowStyleValue(String(localized: "\(records.count) 条"))

                    ProGatedNavigationLink(
                        label: String(localized: "WAF 防火墙"),
                        systemImage: "shield",
                        requiredScope: "zone-waf.read",
                        tint: .purple,
                        showsChevron: true
                    ) {
                        WAFRuleListView(zoneId: zone.id, zoneName: zone.name, session: session)
                    }

                    ProGatedNavigationLink(
                        label: String(localized: "IP 访问规则"),
                        systemImage: "hand.raised",
                        requiredScope: "zone-waf.read",
                        tint: .red,
                        showsChevron: true
                    ) {
                        IPRulesListView(zoneId: zone.id, zoneName: zone.name, session: session)
                    }

                    ProGatedNavigationLink(
                        label: String(localized: "URL 转发"),
                        systemImage: "arrow.triangle.swap",
                        requiredScope: "zone-settings.read",
                        tint: .orange,
                        showsChevron: true
                    ) {
                        BulkRedirectsView(zoneId: zone.id, zoneName: zone.name, session: session)
                    }

                    ProGatedNavigationLink(
                        label: String(localized: "Transform Rules"),
                        systemImage: "arrow.triangle.pull",
                        requiredScope: "zone-settings.read",
                        tint: .blue,
                        showsChevron: true
                    ) {
                        TransformRulesView(zoneId: zone.id, zoneName: zone.name, session: session)
                    }

                    ProGatedNavigationLink(
                        label: String(localized: "负载均衡"),
                        systemImage: "arrow.triangle.branch",
                        requiredScope: "zone-settings.read",
                        tint: .indigo,
                        showsChevron: true
                    ) {
                        LoadBalancerListView(zoneId: zone.id, zoneName: zone.name, session: session)
                    }

                    ProGatedNavigationLink(
                        label: String(localized: "Cache Rules"),
                        systemImage: "clock.arrow.circlepath",
                        requiredScope: "zone-settings.read",
                        tint: .teal,
                        showsChevron: true
                    ) {
                        CacheRulesView(zoneId: zone.id, zoneName: zone.name, session: session)
                    }

                    ProGatedNavigationLink(
                        label: "Rate Limiting",
                        systemImage: "gauge.with.dots.needle.bottom.50percent",
                        requiredScope: "zone-waf.read",
                        feature: .rateLimit,
                        tint: .pink,
                        showsChevron: true
                    ) {
                        RateLimitRulesView(zoneId: zone.id, zoneName: zone.name, session: session)
                    }

                    ProGatedNavigationLink(
                        label: String(localized: "Snippets"),
                        systemImage: "curlybraces",
                        requiredScope: "snippets.read",
                        feature: .snippets,
                        tint: .indigo,
                        showsChevron: true
                    ) {
                        SnippetsListView(zoneId: zone.id, zoneName: zone.name, session: session)
                    }

                    ProGatedNavigationLink(
                        label: "Email Routing",
                        systemImage: "envelope",
                        requiredScope: "email-routing-rule.read",
                        feature: .emailRouting,
                        tint: .pink,
                        showsChevron: true
                    ) {
                        EmailRoutingView(zoneId: zone.id, zoneName: zone.name, session: session)
                    }

                    PermissionGatedNavigationLink(
                        label: "SSL/TLS",
                        systemImage: "lock.shield",
                        requiredScope: "zone-settings.read",
                        tint: .green,
                        showsChevron: true
                    ) {
                        ZoneSSLSettingsView(zoneId: zone.id, zoneName: zone.name, session: session)
                    }

                    PermissionGatedNavigationLink(
                        label: String(localized: "性能与缓存"),
                        systemImage: "speedometer",
                        requiredScope: "zone-settings.read",
                        tint: .teal,
                        showsChevron: true
                    ) {
                        ZonePerformanceView(zoneId: zone.id, session: session)
                    }

                    PermissionGatedNavigationLink(
                        label: String(localized: "SSL 证书"),
                        systemImage: "checkmark.seal",
                        requiredScope: "ssl-and-certificates.read",
                        tint: .green,
                        showsChevron: true
                    ) {
                        ZoneSSLCertsView(zoneId: zone.id, session: session)
                    }
                }

                sslCertificatesSection

                sectionCard(String(localized: "操作")) {
                    settingToggleRow(
                        title: String(localized: "Under Attack 模式"),
                        subtitle: String(localized: "对所有访客启用质询页"),
                        icon: "shield.lefthalf.filled",
                        tint: .red,
                        isOn: actionsViewModel.underAttack,
                        isBusy: actionsViewModel.isTogglingUnderAttack,
                        requestToggle: { on in pendingAction = .underAttack(on) }
                    )

                    settingToggleRow(
                        title: String(localized: "开发模式"),
                        subtitle: String(localized: "临时绕过缓存（3 小时后自动关闭）"),
                        icon: "hammer",
                        tint: .blue,
                        isOn: actionsViewModel.devMode,
                        isBusy: actionsViewModel.isTogglingDevMode,
                        requestToggle: { on in pendingAction = .devMode(on) }
                    )

                    if !actionsViewModel.sslMode.isEmpty {
                        LabeledContent("TLS 加密模式") {
                            Text(actionsViewModel.sslModeLabel)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }

                    settingToggleRow(
                        title: String(localized: "始终使用 HTTPS"),
                        subtitle: String(localized: "将所有 HTTP 请求重定向到 HTTPS"),
                        icon: "lock.fill",
                        tint: .green,
                        isOn: actionsViewModel.alwaysUseHTTPS,
                        isBusy: actionsViewModel.isTogglingAlwaysHTTPS,
                        requestToggle: { on in pendingAction = .alwaysHTTPS(on) }
                    )

                    settingToggleRow(
                        title: String(localized: "自动 HTTPS 重写"),
                        subtitle: String(localized: "自动将 HTTP 链接替换为 HTTPS"),
                        icon: "arrow.triangle.swap",
                        tint: .teal,
                        isOn: actionsViewModel.autoHTTPSRewrites,
                        isBusy: actionsViewModel.isTogglingAutoHTTPS,
                        requestToggle: { on in pendingAction = .autoHTTPSRewrites(on) }
                    )

                    Button {
                        if canPurge {
                            showPurgeConfirm = true
                        } else {
                            deniedScopeHint = "cache.purge"
                            showActionDenied = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            TintIcon(systemImage: "trash", color: .ocOrange)
                            Text("清理全部缓存")
                                .foregroundStyle(.primary)
                            Spacer()
                            if actionsViewModel.isPurging {
                                ProgressView()
                            } else if !canPurge {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .disabled(actionsViewModel.isPurging || actionsViewModel.isTogglingAlwaysHTTPS || actionsViewModel.isTogglingAutoHTTPS)

                    Button {
                        if canPurge {
                            showPurgeURLSheet = true
                        } else {
                            deniedScopeHint = "cache.purge"
                            showActionDenied = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            TintIcon(systemImage: "link", color: .orange)
                            Text("清除指定 URL 缓存")
                                .foregroundStyle(.primary)
                            Spacer()
                            if !canPurge {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                networkOptimizationSection

                cachingSection

                if !zone.nameServers.isEmpty {
                    sectionCard("Name Servers") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(zone.nameServers, id: \.self) { server in
                                Text(server)
                                    .font(.callout.monospaced())
                                    .textSelection(.enabled)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Zone ID footer
                Text("Zone ID · \(zone.id)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)
            }
            .padding()
        }
        .background { SkyBackground() }
        .navigationTitle(zone.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(zone.pinned ? String(localized: "取消固定") : String(localized: "固定到首页"),
                       systemImage: zone.pinned ? "pin.fill" : "pin") {
                    withAnimation(.smooth) {
                        zone.pinned.toggle()
                    }
                    try? modelContext.save()
                }
                .contentTransition(.symbolEffect(.replace))
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: zone.pinned)
        .sensoryFeedback(.success, trigger: actionsViewModel.didPurge)
        .task {
            if canReadSettings {
                await actionsViewModel.loadSettings()
                await loadCertificates()
            }
            await actionsViewModel.loadNetworkSettings()
        }
        .refreshable {
            if auth.hasScope("analytics.read") {
                await analyticsViewModel.refresh()
            }
            if canReadSettings {
                await actionsViewModel.loadSettings()
                await loadCertificates()
            }
            await actionsViewModel.loadNetworkSettings()
        }
        .confirmationDialog(
            pendingAction?.title ?? "",
            isPresented: .init(
                get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingAction
        ) { action in
            Button(action.confirmLabel) {
                Task {
                    switch action {
                    case .underAttack(let on):     await actionsViewModel.setUnderAttack(on)
                    case .devMode(let on):         await actionsViewModel.setDevMode(on)
                    case .alwaysHTTPS(let on):     await actionsViewModel.setAlwaysUseHTTPS(on)
                    case .autoHTTPSRewrites(let on): await actionsViewModel.setAutoHTTPSRewrites(on)
                    }
                }
            }
        } message: { action in
            Text(action.message(zoneName: zone.name))
        }
        .confirmationDialog("清理全部缓存？", isPresented: $showPurgeConfirm, titleVisibility: .visible) {
            Button("清理", role: .destructive) {
                Task { await actionsViewModel.purgeCache() }
            }
        } message: {
            Text("将清空 \(zone.name) 在 Cloudflare 边缘的所有缓存，回源流量会短暂上升。")
        }
        .alert("缓存已清理", isPresented: $showPurgeDone) {
            Button("好", role: .cancel) {}
        } message: {
            Text("边缘节点将在数秒内完成清理。")
        }
        .sheet(isPresented: $showPurgeSheet) {
            PurgeCacheSheet(zoneName: zone.name) { mode, items in
                switch mode {
                case .url:    await actionsViewModel.purgeURLs(items)
                case .prefix: await actionsViewModel.purgePrefixes(items)
                case .host:   await actionsViewModel.purgeHosts(items)
                case .tag:    await actionsViewModel.purgeTags(items)
                }
            }
        }
        .onChange(of: actionsViewModel.didPurge) {
            showPurgeDone = true
        }
        .alert("权限不足", isPresented: $showActionDenied) {
            if let sessionId = auth.currentSessionId, !deniedScopeHint.isEmpty {
                Button("一键重授权") {
                    let scope = deniedScopeHint
                    Task { await auth.reauthorize(sessionId: sessionId, additionalScopes: [scope]) }
                }
            }
            Button("好", role: .cancel) {}
        } message: {
            Text("当前授权未包含此操作所需权限（\(deniedScopeHint)）。点「一键重授权」补齐，无需退出登录。")
        }
        .alert("操作失败", isPresented: .init(
            get: { actionsViewModel.error != nil },
            set: { if !$0 { actionsViewModel.error = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(actionsViewModel.error ?? "")
        }
        .sheet(isPresented: $showPurgeURLSheet) {
            PurgeURLSheet(zoneId: zone.id, zoneName: zone.name, session: session)
        }
    }

    // MARK: - 设置开关行

    private func settingToggleRow(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        isOn: Bool,
        isBusy: Bool,
        requestToggle: @escaping (Bool) -> Void
    ) -> some View {
        HStack(spacing: 12) {
            TintIcon(systemImage: icon, color: tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isBusy {
                ProgressView()
            } else if canEditSettings && actionsViewModel.settingsLoaded {
                Toggle("", isOn: Binding(
                    get: { isOn },
                    set: { on in requestToggle(on) }
                ))
                .labelsHidden()
                .accessibilityLabel(title)
            } else {
                Button {
                    deniedScopeHint = canReadSettings ? "zone-settings.write" : "zone-settings.read"
                    showActionDenied = true
                } label: {
                    if actionsViewModel.settingsLoaded {
                        // 只读授权：显示当前状态
                        Text(isOn ? String(localized: "开") : String(localized: "关"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityValue(actionsViewModel.settingsLoaded ? (isOn ? String(localized: "开") : String(localized: "关")) : "")
                .accessibilityHint("需要额外授权才能修改")
            }
        }
    }

    // MARK: - Hero 卡

    private var heroCard: some View {
        VStack(spacing: 10) {
            ZoneAvatar(domain: zone.name, size: 52)
            Text(zone.name)
                .font(.system(.title2, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    StatusDot(status: zone.status, size: 7)
                        .accessibilityHidden(true)
                    Text(statusText)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(zone.status == "active" ? Color.green : Color.secondary)
                }
                .accessibilityElement(children: .combine)
                PlanBadge(planName: zone.planName)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassIsland()
    }

    // MARK: - 分组卡

    private func sectionCard(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                content()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
            }
            .glassIsland(cornerRadius: OCLayout.chipRadius)
        }
    }

    private func loadCertificates() async {
        guard !certsLoaded else { return }
        let zoneId = zone.id
        async let edgeTask = session.sslCertService.listEdgeCertificates(zoneId: zoneId)
        async let customTask = session.sslCertService.listCustomCertificates(zoneId: zoneId)
        async let usslTask = session.sslCertService.getUniversalSSL(zoneId: zoneId)

        edgeCerts = (try? await edgeTask) ?? []
        customCerts = (try? await customTask) ?? []
        universalSSLEnabled = (try? await usslTask)?.enabled ?? false
        certsLoaded = true
    }

    private func networkToggleRow(
        title: String, subtitle: String, icon: String, tint: Color, isOn: Bool, setting: String
    ) -> some View {
        HStack(spacing: 12) {
            TintIcon(systemImage: icon, color: tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if actionsViewModel.isTogglingNetwork {
                ProgressView()
            } else if canEditSettings {
                Toggle("", isOn: Binding(
                    get: { isOn },
                    set: { _ in Task { await actionsViewModel.toggleSetting(setting, current: isOn) } }
                ))
                .labelsHidden()
            } else {
                Button {
                    deniedScopeHint = "zone-settings.write"
                    showActionDenied = true
                } label: {
                    Text(isOn ? String(localized: "开") : String(localized: "关"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var sslCertificatesSection: some View {
        Group {
            if !edgeCerts.isEmpty || !customCerts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SSL/TLS 证书")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        LabeledContent("Universal SSL") {
                            HStack(spacing: 4) {
                                StatusDot(status: universalSSLEnabled ? "active" : "paused", size: 6)
                                Text(universalSSLEnabled ? String(localized: "已启用") : String(localized: "未启用"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)

                        if let first = edgeCerts.first {
                            Divider().padding(.leading, 14)
                            LabeledContent("边缘证书") {
                                certStatusBadge(first.status)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            if let expires = EdgeCertificate.parseDate(first.expiresOn) {
                                Divider().padding(.leading, 14)
                                LabeledContent("到期时间") {
                                    Text(expires, format: .dateTime.year().month().day())
                                        .foregroundStyle(expires.timeIntervalSinceNow < 30*24*3600 ? .orange : .secondary)
                                        .monospacedDigit()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                            }
                        }

                        if !customCerts.isEmpty {
                            Divider().padding(.leading, 14)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("自定义证书 · \(customCerts.count) 个")
                                    .font(.subheadline.weight(.medium))
                                ForEach(customCerts) { cert in
                                    HStack {
                                        if let hosts = cert.hosts {
                                            Text(hosts.joined(separator: ", "))
                                                .font(.caption)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        certStatusBadge(cert.status)
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                        }
                    }
                    .glassIsland(cornerRadius: OCLayout.chipRadius)
                }
            }
        }
    }

    private var networkOptimizationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("网络优化")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                networkToggleRow(
                    title: "HTTP/2", subtitle: String(localized: "多路复用、头部压缩"),
                    icon: "arrow.left.arrow.right", tint: .blue,
                    isOn: actionsViewModel.http2Enabled, setting: "http2"
                )
                Divider().padding(.leading, 46)
                networkToggleRow(
                    title: "HTTP/3", subtitle: String(localized: "基于 QUIC 的新一代协议"),
                    icon: "arrow.up.arrow.down", tint: .teal,
                    isOn: actionsViewModel.http3Enabled, setting: "http3"
                )
                Divider().padding(.leading, 46)
                networkToggleRow(
                    title: "WebSockets", subtitle: String(localized: "允许 WebSocket 连接通过边缘"),
                    icon: "point.3.connected.trianglepath.dotted", tint: .green,
                    isOn: actionsViewModel.websocketsEnabled, setting: "websockets"
                )
                Divider().padding(.leading, 46)
                networkToggleRow(
                    title: "IPv6", subtitle: String(localized: "启用 IPv6 兼容"),
                    icon: "network", tint: .indigo,
                    isOn: actionsViewModel.ipv6Enabled, setting: "ipv6"
                )
                Divider().padding(.leading, 46)
                networkToggleRow(
                    title: "Brotli", subtitle: String(localized: "比 Gzip 压缩率高 15-20%"),
                    icon: "shippingbox", tint: .purple,
                    isOn: actionsViewModel.brotliEnabled, setting: "brotli"
                )
                Divider().padding(.leading, 46)
                networkToggleRow(
                    title: "Early Hints", subtitle: String(localized: "提前推送关键资源链接"),
                    icon: "lightbulb", tint: .yellow,
                    isOn: actionsViewModel.earlyHintsEnabled, setting: "early_hints"
                )
            }
            .glassIsland(cornerRadius: OCLayout.chipRadius)
        }
    }

    private var cachingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("缓存")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                networkToggleRow(
                    title: "Always Online", subtitle: String(localized: "源站不可用时展示缓存快照"),
                    icon: "clock.arrow.2.circlepath", tint: .orange,
                    isOn: actionsViewModel.alwaysOnlineEnabled, setting: "always_online"
                )

                if !actionsViewModel.cachingLevel.isEmpty {
                    Divider().padding(.leading, 46)
                    HStack(spacing: 12) {
                        TintIcon(systemImage: "tray.full", color: .blue)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("缓存级别")
                            Text("控制查询字符串对缓存的影响")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if canEditSettings {
                            Picker("", selection: Binding(
                                get: { actionsViewModel.cachingLevel },
                                set: { level in
                                    Task { await actionsViewModel.setCachingLevel(level) }
                                }
                            )) {
                                Text("标准").tag("standard")
                                Text("忽略查询").tag("no_query")
                                Text("激进").tag("aggressive")
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        } else {
                            Text(actionsViewModel.cachingLevelLabel)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
            }
            .glassIsland(cornerRadius: OCLayout.chipRadius)
        }
    }

    private func certStatusBadge(_ status: String?) -> some View {
        let s = status ?? "unknown"
        let color: Color = {
            switch s {
            case "active":      return .green
            case "pending":     return .orange
            case "expired":     return .red
            default:            return .secondary
            }
        }()
        return Text(s)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }
}

// MARK: - 操作区待确认动作

/// 「操作」区的开关动作：先弹确认说明影响，确认后才调 API
private nonisolated enum PendingZoneAction: Identifiable {
    case underAttack(Bool)
    case devMode(Bool)
    case alwaysHTTPS(Bool)
    case autoHTTPSRewrites(Bool)

    var id: String {
        switch self {
        case .underAttack(let on):   "underAttack-\(on)"
        case .devMode(let on):       "devMode-\(on)"
        case .alwaysHTTPS(let on):   "alwaysHTTPS-\(on)"
        case .autoHTTPSRewrites(let on): "autoHTTPS-\(on)"
        }
    }

    var title: String {
        switch self {
        case .underAttack(true):  String(localized: "开启 Under Attack 模式？")
        case .underAttack(false): String(localized: "关闭 Under Attack 模式？")
        case .devMode(true):      String(localized: "开启开发模式？")
        case .devMode(false):     String(localized: "关闭开发模式？")
        case .alwaysHTTPS(true):  String(localized: "开启始终使用 HTTPS？")
        case .alwaysHTTPS(false): String(localized: "关闭始终使用 HTTPS？")
        case .autoHTTPSRewrites(true):  String(localized: "开启自动 HTTPS 重写？")
        case .autoHTTPSRewrites(false): String(localized: "关闭自动 HTTPS 重写？")
        }
    }

    var confirmLabel: String {
        switch self {
        case .underAttack(true), .devMode(true), .alwaysHTTPS(true), .autoHTTPSRewrites(true):
            String(localized: "确认开启")
        case .underAttack(false), .devMode(false), .alwaysHTTPS(false), .autoHTTPSRewrites(false):
            String(localized: "确认关闭")
        }
    }

    func message(zoneName: String) -> String {
        switch self {
        case .underAttack(true):
            String(localized: "开启后，访问 \(zoneName) 的所有访客都会先看到约 5 秒的质询页，可能影响正常用户体验。适合正在遭受攻击时使用。")
        case .underAttack(false):
            String(localized: "关闭后，\(zoneName) 的安全级别将恢复为「中」。")
        case .devMode(true):
            String(localized: "开启后，\(zoneName) 将临时绕过 Cloudflare 缓存，源站负载会上升；3 小时后自动关闭。")
        case .devMode(false):
            String(localized: "关闭后，\(zoneName) 立即恢复缓存加速。")
        case .alwaysHTTPS(true):
            String(localized: "开启后，所有对 \(zoneName) 的 HTTP 请求将被 301 重定向到 HTTPS。")
        case .alwaysHTTPS(false):
            String(localized: "关闭后，\(zoneName) 将不再强制重定向 HTTP 到 HTTPS。")
        case .autoHTTPSRewrites(true):
            String(localized: "开启后，\(zoneName) 页面中的 HTTP 链接将被自动替换为 HTTPS。")
        case .autoHTTPSRewrites(false):
            String(localized: "关闭后，\(zoneName) 页面中的 HTTP 链接将保持原样。")
        }
    }
}

// MARK: - 行尾 value 标注

private extension View {
    /// 给 PermissionGatedNavigationLink 行附加右侧 value 文本的轻量包装
    func listRowStyleValue(_ value: String) -> some View {
        overlay(alignment: .trailing) {
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.trailing, 24)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - 按 URL 清除缓存

private struct PurgeURLSheet: View {

    let zoneId: String
    let zoneName: String
    let session: SessionStore

    @Environment(\.dismiss) private var dismiss

    @State private var urlText = ""
    @State private var isPurging = false
    @State private var error: String?
    @State private var didPurge = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if didPurge {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("缓存已清理")
                            .font(.headline)
                        Text("指定的 URL 将在边缘节点完成清理。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("输入要清除缓存的完整 URL")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("https://\(zoneName)/path", text: $urlText)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()

                        Text("一次可输入多个 URL，每行一个")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button {
                        Task { await purge() }
                    } label: {
                        HStack {
                            if isPurging {
                                ProgressView()
                            }
                            Text("清除缓存")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPurging)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("清除指定缓存")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .alert("清除失败", isPresented: .init(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(error ?? "")
            }
        }
    }

    private func purge() async {
        let lines = urlText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { return }
        isPurging = true
        defer { isPurging = false }
        do {
            _ = try await session.zoneSettingsService.purgeByURL(
                zoneId: zoneId,
                urls: lines
            )
            didPurge = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}
