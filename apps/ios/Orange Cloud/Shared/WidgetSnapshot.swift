//
//  WidgetSnapshot.swift
//  Orange Cloud（主 App 与 Widget Extension 共享）
//
//  App 刷新 Zone 后写入 App Group，Widget 时间线读取展示。
//

import Foundation

nonisolated struct WidgetSnapshot: Codable, Sendable {

    var accountName: String
    var totalZones:  Int
    var activeZones: Int
    var updatedAt:   Date

    static let appGroupID = "group.jiamin.chen.Orange-Cloud"
    private static let key = "widgetSnapshot"

    static func load() -> WidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID),
              let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.key)
    }
}

// MARK: - 单 Zone 指标快照（Zone 类 Widget 的数据源，App 刷新时写入）

nonisolated struct WidgetZoneMetrics: Codable, Sendable, Identifiable {
    var id:             String
    var name:           String
    var requests:       Int
    var bytes:          Int
    var threats:        Int
    var uniques:        Int
    var cacheHitRate:   Double?     // 0–100
    var requestsTrend:  Double?     // 与前一个 24h 的百分比变化
    var requestsSeries: [Int]       // 24h 逐小时
    var bytesSeries:    [Int]
    var updatedAt:      Date
}

// MARK: - 用量快照（用量 Widget 的数据源，按服务分组、行级状态条）

nonisolated struct WidgetUsageRow: Codable, Sendable {
    var title:     String     // 如 "请求 · 今日"
    var used:      Int
    var quota:     Int?       // nil = 无参考额度（不画条）
    var valueText: String     // 预格式化的展示值
}

nonisolated struct WidgetUsageService: Codable, Sendable, Identifiable {
    var id:   String          // "workers" | "r2" | "d1" | "kv"
    var name: String
    var rows: [WidgetUsageRow]
}

nonisolated struct WidgetUsageData: Codable, Sendable {
    var services:  [WidgetUsageService]
    var updatedAt: Date
}

// MARK: - App Group 读写

nonisolated enum WidgetDataStore {

    private static let zonesKey = "widgetZoneMetrics"
    private static let usageKey = "widgetUsageData"
    private static let analyticsAvailableKey = "accountAnalyticsAvailable"

    static func saveZones(_ zones: [WidgetZoneMetrics]) {
        guard let defaults = UserDefaults(suiteName: WidgetSnapshot.appGroupID),
              let data = try? JSONEncoder().encode(zones) else { return }
        defaults.set(data, forKey: zonesKey)
    }

    static func loadZones() -> [WidgetZoneMetrics] {
        guard let defaults = UserDefaults(suiteName: WidgetSnapshot.appGroupID),
              let data = defaults.data(forKey: zonesKey),
              let zones = try? JSONDecoder().decode([WidgetZoneMetrics].self, from: data) else { return [] }
        return zones
    }

    static func saveUsage(_ usage: WidgetUsageData) {
        guard let defaults = UserDefaults(suiteName: WidgetSnapshot.appGroupID),
              let data = try? JSONEncoder().encode(usage) else { return }
        defaults.set(data, forKey: usageKey)
    }

    static func loadUsage() -> WidgetUsageData? {
        guard let defaults = UserDefaults(suiteName: WidgetSnapshot.appGroupID),
              let data = defaults.data(forKey: usageKey) else { return nil }
        return try? JSONDecoder().decode(WidgetUsageData.self, from: data)
    }

    /// 当前账号是否拥有账户级数据（analytics）查询权限。未知时默认 true，避免首次误报不可用。
    static func saveAccountAnalyticsAvailable(_ available: Bool) {
        UserDefaults(suiteName: WidgetSnapshot.appGroupID)?.set(available, forKey: analyticsAvailableKey)
    }

    static func loadAccountAnalyticsAvailable() -> Bool {
        guard let defaults = UserDefaults(suiteName: WidgetSnapshot.appGroupID),
              defaults.object(forKey: analyticsAvailableKey) != nil else { return true }
        return defaults.bool(forKey: analyticsAvailableKey)
    }
}
