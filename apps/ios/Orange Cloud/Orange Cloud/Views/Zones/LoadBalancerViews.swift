//
//  LoadBalancerViews.swift
//  Orange Cloud
//
//  Load Balancing：列表 + 详情（Pool / Origin / Monitor 展开）。
//

import SwiftUI

// MARK: - 负载均衡器列表

struct LoadBalancerListView: View {

    let zoneId: String
    let zoneName: String
    let session: SessionStore

    @Environment(AuthManager.self) private var auth

    @State private var loadBalancers: [LoadBalancer] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var searchText = ""

    private var filteredBalancers: [LoadBalancer] {
        guard !searchText.isEmpty else { return loadBalancers }
        return loadBalancers.filter { lb in
            (lb.name ?? "").localizedCaseInsensitiveContains(searchText) ||
            (lb.description ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if isLoading && loadBalancers.isEmpty {
                SkeletonList(rows: 6, trailing: true)
            } else if !searchText.isEmpty && filteredBalancers.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if loadBalancers.isEmpty {
                emptyState
            } else {
                lbList
            }
        }
        .background { SkyBackground() }
        .searchable(text: $searchText, prompt: "搜索负载均衡器")
        .navigationTitle("负载均衡")
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

    private var lbList: some View {
        List {
            ForEach(filteredBalancers) { lb in
                NavigationLink {
                    LoadBalancerDetailView(
                        loadBalancer: lb,
                        zoneId: zoneId,
                        session: session
                    )
                } label: {
                    lbRow(lb)
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

    private func lbRow(_ lb: LoadBalancer) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(lb.name ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if let enabled = lb.enabled {
                    enabledBadge(enabled)
                }
            }

            HStack(spacing: 6) {
                if let proxied = lb.proxied {
                    modePill(proxied ? String(localized: "CDN") : String(localized: "DNS Only"), color: .blue)
                }
                modePill(lb.steeringLabel, color: .purple)
                modePill(lb.affinityLabel, color: .orange)

                if let pools = lb.defaultPools {
                    Text("\(pools.count) 个池")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let ttl = lb.ttl {
                    Text("TTL \(ttl)s")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if let desc = lb.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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

    private func modePill(_ label: String, color: Color) -> some View {
        Text(label)
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(color.opacity(0.1), in: Capsule())
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "暂无负载均衡器",
            systemImage: "arrow.triangle.branch",
            description: Text("\(zoneName) 尚未配置 Load Balancing。\n前往 dash.cloudflare.com → Traffic → Load Balancing 创建。")
        )
    }

    private func load() async {
        isLoading = true
        error = nil
        do {
            loadBalancers = try await session.loadBalancerService.listLoadBalancers(zoneId: zoneId)
        } catch {
            self.error = error.localizedDescription
            loadBalancers = []
        }
        isLoading = false
    }
}

// MARK: - 负载均衡器详情

struct LoadBalancerDetailView: View {

    let loadBalancer: LoadBalancer
    let zoneId: String
    let session: SessionStore

    @Environment(AuthManager.self)    private var auth
    @State private var pools: [LBPool] = []
    @State private var monitors: [String: LBMonitor] = [:]
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading && pools.isEmpty {
                SkeletonList(rows: 6, trailing: true)
            } else {
                content
            }
        }
        .background { SkyBackground() }
        .navigationTitle(loadBalancer.name ?? String(localized: "详情"))
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

    private var content: some View {
        List {
            headerSection
            poolsSection
        }
        .daybreakList()
        .listRowSpacing(4)
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loadBalancer.name ?? "")
                            .font(.title3.weight(.semibold))
                        if let desc = loadBalancer.description, !desc.isEmpty {
                            Text(desc)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if let enabled = loadBalancer.enabled {
                        enabledBadge(enabled)
                    }
                }

                Divider().padding(.vertical, 4)

                configGrid
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    private var configGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            configCell(String(localized: "调度策略"), loadBalancer.steeringLabel)
            configCell(String(localized: "亲和性"), loadBalancer.affinityLabel)
            configCell(String(localized: "模式"), loadBalancer.proxied == true ? String(localized: "CDN") : String(localized: "DNS Only"))
            if let ttl = loadBalancer.ttl {
                configCell(String(localized: "TTL"), "\(ttl)s")
            }
            if let affinityTTL = loadBalancer.sessionAffinityTTL {
                configCell(String(localized: "亲和 TTL"), "\(affinityTTL)s")
            }
            if let pools = loadBalancer.defaultPools {
                configCell(String(localized: "默认池"), "\(pools.count) 个")
            }
        }
    }

    private func configCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
    }

    private var poolsSection: some View {
        Section(String(localized: "源站池")) {
            if pools.isEmpty {
                Text("暂无关联源站池")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                ForEach(pools) { pool in
                    poolRow(pool)
                }
            }
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }

    private func poolRow(_ pool: LBPool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "square.stack.3d.up")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                Text(pool.name ?? pool.id ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if let enabled = pool.enabled {
                    enabledBadge(enabled)
                }
            }

            if let desc = pool.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            originsStrip(pool)

            HStack(spacing: 6) {
                if let min = pool.minimumOrigins {
                    pill("最低 \(min) 个源", color: .secondary)
                }
                if let regions = pool.checkRegions, !regions.isEmpty {
                    pill("\(regions.count) 个检测区域", color: .blue)
                }
                if let monitorId = pool.monitor, !monitorId.isEmpty {
                    if let m = monitors[monitorId] {
                        pill(m.urlPreview, color: .purple)
                    } else {
                        pill(String(localized: "有监控"), color: .purple)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func originsStrip(_ pool: LBPool) -> some View {
        guard let origins = pool.origins, !origins.isEmpty else {
            return AnyView(EmptyView())
        }
        return AnyView(
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 4) {
                ForEach(origins) { origin in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(origin.enabled == false ? Color.secondary : Color.green)
                            .frame(width: 6, height: 6)
                        Text(origin.name ?? origin.address ?? "")
                            .font(.caption2.monospaced())
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(origin.weightLabel)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                }
            }
        )
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

    private func pill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(color.opacity(0.1), in: Capsule())
    }

    private func load() async {
        isLoading = true
        error = nil
        do {
            guard let accountId = session.selectedAccount?.id else {
                error = String(localized: "未选择账户")
                isLoading = false
                return
            }
            let poolIds = loadBalancer.defaultPools ?? (loadBalancer.fallbackPool.map { [$0] } ?? [])
            let allPools = try await session.loadBalancerService.listPools(accountId: accountId)
            pools = allPools.filter { poolIds.contains($0.id ?? "") }
            if pools.isEmpty {
                pools = allPools
            }

            var monitorMap: [String: LBMonitor] = [:]
            let allMonitors = try await session.loadBalancerService.listMonitors(accountId: accountId)
            for m in allMonitors {
                if let mid = m.id { monitorMap[mid] = m }
            }
            monitors = monitorMap
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
