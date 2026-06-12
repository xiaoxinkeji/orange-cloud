//
//  DashboardViewModel.swift
//  Orange Cloud
//
//  Dashboard 域名卡片的 24h 流量数据（一次多 Zone GraphQL 查询）。
//

import Foundation
import Observation
import SwiftData
import WidgetKit

@Observable
@MainActor
final class DashboardViewModel {

    private(set) var trafficByZone: [String: ZoneTrafficBundle] = [:]
    private(set) var usage: AccountUsage?
    /// 资产数（Dashboard 指标格）：接口或权限不可用时保持 nil，格子自动回退
    private(set) var r2BucketCount: Int?
    private(set) var d1DatabaseCount: Int?
    /// 订阅识别结果；nil = 接口不可用（OAuth 无 billing scope 时的常态），回退本地预设
    private(set) var billing: BillingInfo?
    var isLoading = false

    /// 全账号 DNS 记录总数（首屏 total_count 汇总；nil = 未加载/无权限，回退已同步缓存计数）
    private(set) var dnsRecordTotal: Int?
    private(set) var isLoadingAssets = false

    private var loadedZoneIds: Set<String> = []
    private var assetsLoadedForAccount: String?
    private var usageLoadedForAccount: String?
    private var billingAttemptedForAccount: String?
    private let analyticsService: AnalyticsService
    private let accountService: AccountService
    private let r2Service: R2Service
    private let d1Service: D1Service
    private let zoneService: ZoneService
    private let workerService: WorkerService
    private let dnsService: DNSService

    init(
        analyticsService: AnalyticsService,
        accountService: AccountService,
        r2Service: R2Service,
        d1Service: D1Service,
        zoneService: ZoneService,
        workerService: WorkerService,
        dnsService: DNSService
    ) {
        self.analyticsService = analyticsService
        self.accountService = accountService
        self.r2Service = r2Service
        self.d1Service = d1Service
        self.zoneService = zoneService
        self.workerService = workerService
        self.dnsService = dnsService
    }

    /// 首屏资产统计：拉 Zone / Worker 列表同步进缓存（指标格直接从 @Query 读到数量），
    /// DNS 记录数对每个 Zone 用 total_count 轻量汇总，不必等用户逐页进入 DNS 列表。
    /// 同一账号只拉一次，下拉刷新强制重拉。
    func loadAssets(
        accountId: String,
        accountName: String,
        canReadWorkers: Bool,
        canReadDNS: Bool,
        context: ModelContext,
        force: Bool = false
    ) async {
        guard force || assetsLoadedForAccount != accountId else { return }
        guard !isLoadingAssets else { return }
        isLoadingAssets = true
        defer { isLoadingAssets = false }

        // Zone 列表是 DNS 统计的基础；失败保持未加载态，下次进入重试
        guard let zones = try? await zoneService.listZones(accountId: accountId) else { return }
        try? CacheSync.syncZones(zones, accountId: accountId, accountName: accountName, context: context)

        if canReadWorkers, let scripts = try? await workerService.listScripts(accountId: accountId) {
            try? CacheSync.syncWorkers(scripts, accountId: accountId, context: context)
        }

        if canReadDNS {
            // 每个 Zone 一个轻量请求并发取 total_count；域名特别多时只统计前 50 个
            let service = dnsService
            let zoneIds = zones.prefix(50).map(\.id)
            let total = await withTaskGroup(of: Int?.self) { group in
                for zoneId in zoneIds {
                    group.addTask {
                        try? await service.recordCount(zoneId: zoneId)
                    }
                }
                var sum = 0
                var anySuccess = zoneIds.isEmpty
                for await count in group where count != nil {
                    sum += count!
                    anySuccess = true
                }
                return anySuccess ? sum : nil as Int?
            }
            if let total {
                dnsRecordTotal = total
            }
        }

        assetsLoadedForAccount = accountId
    }

    /// 账号用量（Workers/R2）。同一账号只拉一次，下拉刷新强制重拉。
    /// 周期起点优先级：订阅接口（best-effort）→ 手动账单日（fallbackPeriodStart）→ 自然月。
    func loadUsage(accountId: String, fallbackPeriodStart: Date? = nil, force: Bool = false) async {
        guard force || usageLoadedForAccount != accountId else { return }

        if force || billingAttemptedForAccount != accountId {
            billingAttemptedForAccount = accountId
            billing = (try? await accountService.listSubscriptions(accountId: accountId))
                .map(BillingInfo.derive(from:))
        }

        // 订阅周期有效才采用：必须在过去、未结束，且不超过 GraphQL 数据留存（约 31 天）
        var periodStart: Date?
        if let billing,
           let start = billing.periodStart,
           start <= Date(),
           start > Date().addingTimeInterval(-31 * 24 * 3600),
           billing.periodEnd.map({ $0 > Date() }) ?? true {
            periodStart = start
        }
        periodStart = periodStart ?? fallbackPeriodStart

        // 加载失败不打扰 Dashboard（用量区显示占位）
        guard var usage = try? await analyticsService.accountUsage(accountId: accountId, periodStart: periodStart) else {
            return
        }
        // 存储改用 REST 指标（与 Dashboard 同源、免费额度只计 Standard），失败保留 GraphQL 值
        if let metrics = try? await r2Service.accountMetrics(accountId: accountId) {
            usage.r2StorageBytes = metrics.standardBytes
            usage.r2ObjectCount = metrics.standardObjects
        }
        // 存储桶数（指标格用，失败保持 nil）
        if let buckets = try? await r2Service.listBuckets(accountId: accountId) {
            r2BucketCount = buckets.count
        }
        // CPU 总耗时（独立查询，schema 不支持时保持 nil → UI 回退分位展示）
        if let cpu = try? await analyticsService.workersCpuTotals(accountId: accountId, periodStart: periodStart) {
            usage.cpuTimeMonthUs = cpu.monthUs
            usage.cpuTimeTodayUs = cpu.todayUs
        }
        // D1 行读/写（独立查询）+ 存储（REST 数据库列表 fileSize 求和，需 d1.read）
        usage.d1Usage = try? await analyticsService.d1Usage(accountId: accountId, periodStart: periodStart)
        if let databases = try? await d1Service.listDatabases(accountId: accountId) {
            usage.d1StorageBytes = databases.reduce(0) { $0 + ($1.fileSize ?? 0) }
            d1DatabaseCount = databases.count
        }
        // KV 读/写 + 存储（独立查询）
        usage.kvUsage = try? await analyticsService.kvUsage(accountId: accountId, periodStart: periodStart)
        usage.kvStorageBytes = try? await analyticsService.kvStorageBytes(accountId: accountId)
        self.usage = usage
        usageLoadedForAccount = accountId
    }

    /// 拉取各 Zone 的 24h 流量。zone 集合没变化时跳过（Tab 切换不重复请求）。
    /// 成功后写入 Widget 快照（按域名的指标卡数据源）。
    func loadTraffic(zones: [(id: String, name: String)], force: Bool = false) async {
        let idSet = Set(zones.map(\.id))
        guard !idSet.isEmpty else { return }
        guard force || idSet != loadedZoneIds, !isLoading else { return }

        isLoading = true
        // 流量数据加载失败不打扰 Dashboard（卡片自动隐藏图表）
        if let traffic = try? await analyticsService.trafficByZone24h(zoneIds: zones.map(\.id)) {
            trafficByZone = traffic
            loadedZoneIds = idSet
            writeZoneWidgetSnapshots(zones: zones, traffic: traffic)
        }
        isLoading = false
    }

    /// Zone 指标快照 → App Group（Widget 数据源）
    private func writeZoneWidgetSnapshots(zones: [(id: String, name: String)], traffic: [String: ZoneTrafficBundle]) {
        let metrics: [WidgetZoneMetrics] = zones.compactMap { zone in
            guard let bundle = traffic[zone.id], !bundle.points.isEmpty else { return nil }
            let points = bundle.points
            let requests = points.reduce(0) { $0 + $1.requests }
            let cached = points.reduce(0) { $0 + $1.cachedRequests }
            var trend: Double?
            if let previous = bundle.previousRequests, previous > 0 {
                trend = (Double(requests) - Double(previous)) / Double(previous) * 100
            }
            return WidgetZoneMetrics(
                id: zone.id,
                name: zone.name,
                requests: requests,
                bytes: points.reduce(0) { $0 + $1.bytes },
                threats: points.reduce(0) { $0 + $1.threats },
                uniques: points.reduce(0) { $0 + $1.uniques },
                cacheHitRate: requests > 0 ? Double(cached) / Double(requests) * 100 : nil,
                requestsTrend: trend,
                requestsSeries: points.map(\.requests),
                bytesSeries: points.map(\.bytes),
                updatedAt: Date()
            )
        }
        guard !metrics.isEmpty else { return }
        WidgetDataStore.saveZones(metrics)
        WidgetCenter.shared.reloadTimelines(ofKind: "ZoneStatWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "ZoneChartWidget")
    }
}
