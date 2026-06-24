//
//  LoadBalancerModels.swift
//  Orange Cloud
//
//  Load Balancing 模型：LoadBalancer → Pool → Monitor → Origin。
//

import Foundation

// MARK: - Load Balancer

nonisolated struct LoadBalancer: Codable, Identifiable, Sendable {
    let id: String?
    let name: String?
    let enabled: Bool?
    let description: String?
    let fallbackPool: String?
    let defaultPools: [String]?
    let regionPools: [String: [String]]?
    let proxied: Bool?
    let sessionAffinity: String?
    let sessionAffinityTTL: Int?
    let steeringPolicy: String?
    let ttl: Int?
    let createdAt: String?
    let modifiedAt: String?

    var uid: String { id ?? UUID().uuidString }

    var steeringLabel: String {
        switch steeringPolicy {
        case "off":                  String(localized: "关闭")
        case "geo":                  String(localized: "地理位置")
        case "random":               String(localized: "随机")
        case "dynamic_latency":      String(localized: "动态延迟")
        case "proximity":            String(localized: "就近路由")
        default:                     steeringPolicy ?? ""
        }
    }

    var affinityLabel: String {
        switch sessionAffinity {
        case "none":                 String(localized: "无")
        case "cookie":               String(localized: "Cookie")
        case "ip_cookie":            String(localized: "IP + Cookie")
        default:                     sessionAffinity ?? ""
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, enabled, description, proxied, ttl
        case fallbackPool        = "fallback_pool"
        case defaultPools        = "default_pools"
        case regionPools         = "region_pools"
        case sessionAffinity     = "session_affinity"
        case sessionAffinityTTL  = "session_affinity_ttl"
        case steeringPolicy      = "steering_policy"
        case createdAt           = "created_on"
        case modifiedAt          = "modified_on"
    }
}

// MARK: - Pool

nonisolated struct LBPool: Codable, Identifiable, Sendable {
    let id: String?
    let name: String?
    let description: String?
    let enabled: Bool?
    let minimumOrigins: Int?
    let monitor: String?
    let origins: [LBOrigin]?
    let notificationEmail: String?
    let checkRegions: [String]?
    let createdAt: String?
    let modifiedAt: String?

    var uid: String { id ?? UUID().uuidString }

    var healthyCount: Int { origins?.filter { $0.enabled != false }.count ?? 0 }

    enum CodingKeys: String, CodingKey {
        case id, name, description, enabled, monitor, origins
        case minimumOrigins     = "minimum_origins"
        case notificationEmail  = "notification_email"
        case checkRegions       = "check_regions"
        case createdAt          = "created_on"
        case modifiedAt         = "modified_on"
    }
}

// MARK: - Origin

nonisolated struct LBOrigin: Codable, Identifiable, Sendable {
    let name: String?
    let address: String?
    let enabled: Bool?
    let weight: Double?

    var uid: String { name ?? address ?? UUID().uuidString }

    var weightLabel: String {
        guard let w = weight else { return "" }
        return String(format: "%.0f%%", w * 100)
    }
}

// MARK: - Monitor

nonisolated struct LBMonitor: Codable, Identifiable, Sendable {
    let id: String?
    let type: String?
    let description: String?
    let method: String?
    let path: String?
    let header: [String: [String]]?
    let port: Int?
    let interval: Int?
    let retries: Int?
    let timeout: Int?
    let expectedBody: String?
    let expectedCodes: String?
    let followRedirects: Bool?
    let allowInsecure: Bool?
    let consecutiveUp: Int?
    let consecutiveDown: Int?
    let probeZone: String?
    let createdAt: String?
    let modifiedAt: String?

    var uid: String { id ?? UUID().uuidString }

    var urlPreview: String {
        let m = method ?? "GET"
        let p = path ?? "/"
        let mp = port.map { ":\($0)" } ?? ""
        return "\(m) \(p)\(mp)"
    }

    var intervalLabel: String {
        guard let i = interval else { return "" }
        return "\(i)s"
    }

    enum CodingKeys: String, CodingKey {
        case id, type, description, method, path, header, port
        case interval, retries, timeout, followRedirects, allowInsecure
        case probeZone
        case expectedBody     = "expected_body"
        case expectedCodes    = "expected_codes"
        case consecutiveUp    = "consecutive_up"
        case consecutiveDown  = "consecutive_down"
        case createdAt        = "created_on"
        case modifiedAt       = "modified_on"
    }
}

// MARK: - API 列表包装

nonisolated struct LoadBalancerListResponse: Codable, Sendable {
    let id: String?
    let name: String?
    let description: String?
}
