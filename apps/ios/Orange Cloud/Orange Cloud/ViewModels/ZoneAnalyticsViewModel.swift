//
//  ZoneAnalyticsViewModel.swift
//  Orange Cloud
//
//  Zone 流量分析：当前 + 前一周期并发加载（环比趋势），会话级内存缓存。
//  不进 SwiftData——时间窗口随"现在"滚动，持久化命中率几乎为零。
//

import Foundation
import Observation

@Observable
@MainActor
final class ZoneAnalyticsViewModel {

    var selectedRange: AnalyticsTimeRange = .last24h
    var isLoading = false
    var error: String?
    private(set) var points: [TrafficDataPoint] = []
    private(set) var previousPoints: [TrafficDataPoint] = []

    private var cache: [AnalyticsTimeRange: (current: [TrafficDataPoint], previous: [TrafficDataPoint])] = [:]
    private let analyticsService: AnalyticsService
    private let zoneId: String

    init(analyticsService: AnalyticsService, zoneId: String) {
        self.analyticsService = analyticsService
        self.zoneId = zoneId
    }

    // MARK: - 汇总

    var totalRequests:  Int { points.reduce(0) { $0 + $1.requests } }
    var totalBytes:     Int { points.reduce(0) { $0 + $1.bytes } }
    var totalThreats:   Int { points.reduce(0) { $0 + $1.threats } }
    var totalPageViews: Int { points.reduce(0) { $0 + $1.pageViews } }
    var totalUniques:   Int { points.reduce(0) { $0 + $1.uniques } }
    private var totalCachedRequests: Int { points.reduce(0) { $0 + $1.cachedRequests } }

    /// 缓存命中率（0–100），无请求时 nil
    var cacheHitRate: Double? {
        guard totalRequests > 0 else { return nil }
        return Double(totalCachedRequests) / Double(totalRequests) * 100
    }

    // MARK: - 环比趋势（与前一等长周期对比）

    private var prevRequests: Int { previousPoints.reduce(0) { $0 + $1.requests } }
    private var prevBytes:    Int { previousPoints.reduce(0) { $0 + $1.bytes } }
    private var prevThreats:  Int { previousPoints.reduce(0) { $0 + $1.threats } }
    private var prevUniques:  Int { previousPoints.reduce(0) { $0 + $1.uniques } }
    private var prevCachedRequests: Int { previousPoints.reduce(0) { $0 + $1.cachedRequests } }

    var requestsTrend: Double? { percentChange(current: totalRequests, previous: prevRequests) }
    var bytesTrend:    Double? { percentChange(current: totalBytes, previous: prevBytes) }
    var threatsTrend:  Double? { percentChange(current: totalThreats, previous: prevThreats) }
    var uniquesTrend:  Double? { percentChange(current: totalUniques, previous: prevUniques) }

    /// 命中率变化（百分点差）
    var cacheHitTrendPt: Double? {
        guard let current = cacheHitRate, prevRequests > 0 else { return nil }
        let previous = Double(prevCachedRequests) / Double(prevRequests) * 100
        return current - previous
    }

    private func percentChange(current: Int, previous: Int) -> Double? {
        guard previous > 0 else { return nil }
        return (Double(current) - Double(previous)) / Double(previous) * 100
    }

    // MARK: - 加载

    func load(force: Bool = false) async {
        if !force, let cached = cache[selectedRange] {
            points = cached.current
            previousPoints = cached.previous
            return
        }
        isLoading = true
        error = nil
        do {
            // 当前与前一周期并发拉取；前一周期失败不阻塞主数据（趋势显示为空）
            async let currentTask = analyticsService.zoneTraffic(zoneId: zoneId, range: selectedRange)
            async let previousTask = analyticsService.zoneTrafficPrevious(zoneId: zoneId, range: selectedRange)

            let current = try await currentTask
            let previous = (try? await previousTask) ?? []

            cache[selectedRange] = (current, previous)
            points = current
            previousPoints = previous
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    /// 下拉刷新：清空缓存重新拉取
    func refresh() async {
        cache.removeAll()
        await load(force: true)
    }
}
