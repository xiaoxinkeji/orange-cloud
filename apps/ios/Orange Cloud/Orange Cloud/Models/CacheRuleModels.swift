//
//  CacheRuleModels.swift
//  Orange Cloud
//
//  Cache Rules 模型：精细化的缓存策略规则。
//

import Foundation

nonisolated struct CacheRuleset: Codable, Sendable {
    let id: String?
    let rules: [CacheRule]?
}

nonisolated struct CacheRule: Codable, Identifiable, Sendable {
    let id: String?
    let enabled: Bool?
    let description: String?
    let expression: String?
    let action: String?
    let actionParameters: CacheRuleParams?

    var uid: String { id ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case id, enabled, description, expression, action
        case actionParameters = "action_parameters"
    }
}

nonisolated struct CacheRuleParams: Codable, Sendable {
    let cache: Bool?
    let edgeTTL: CacheTTL?
    let browserTTL: CacheTTL?

    enum CodingKeys: String, CodingKey {
        case cache
        case edgeTTL     = "edge_ttl"
        case browserTTL  = "browser_ttl"
    }
}

nonisolated struct CacheTTL: Codable, Sendable {
    let mode: String?
    let `default`: Int?
    let statusCodeTTL: [StatusCodeTTL]?

    var modeLabel: String {
        switch mode {
        case "override_origin":         String(localized: "覆盖源站")
        case "respect_origin":          String(localized: "尊重源站")
        case "bypass_by_default":       String(localized: "默认绕过")
        default:                        mode ?? ""
        }
    }

    var defaultLabel: String? {
        guard let d = `default` else { return nil }
        if d >= 3600 { return "\(d / 3600)h" }
        if d >= 60   { return "\(d / 60)min" }
        return "\(d)s"
    }

    enum CodingKeys: String, CodingKey {
        case mode, `default`
        case statusCodeTTL = "status_code_ttl"
    }
}

nonisolated struct StatusCodeTTL: Codable, Sendable {
    let statusCode: Int?
    let value: Int?

    var label: String {
        let code = statusCode.map { "\($0)" } ?? ""
        let ttl = value.map { v -> String in
            if v >= 3600 { return "\(v / 3600)h" }
            if v >= 60   { return "\(v / 60)min" }
            return "\(v)s"
        } ?? ""
        return "\(code) → \(ttl)"
    }

    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case value
    }
}
