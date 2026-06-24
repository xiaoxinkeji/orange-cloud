//
//  FirewallRuleModels.swift
//  Orange Cloud
//
//  IP 访问规则模型：IP/ASN/国家级的允许或阻止规则。
//

import Foundation

nonisolated struct IPAccessRule: Codable, Identifiable, Sendable {
    let id: String
    let mode: String
    let notes: String?
    let configuration: IPRuleConfig
    let createdOn: String?
    let modifiedOn: String?
    let allowedModes: [String]?

    var isBlock: Bool { mode == "block" || mode == "challenge" }
    var modeLabel: String {
        Self.modeLabel(mode)
    }

    static func modeLabel(_ mode: String) -> String {
        switch mode {
        case "block":              String(localized: "阻止")
        case "challenge":          String(localized: "质询")
        case "whitelist":          String(localized: "允许")
        case "js_challenge":       String(localized: "JS 质询")
        case "managed_challenge":  String(localized: "托管质询")
        default:                   mode
        }
    }

    var targetLabel: String {
        let t = configuration.target
        switch t {
        case "ip":        String(localized: "IP")
        case "ip6":       String(localized: "IPv6")
        case "ip_range":  String(localized: "IP 段")
        case "asn":       String(localized: "ASN")
        case "country":   String(localized: "国家")
        default:          t
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, mode, notes, configuration
        case createdOn  = "created_on"
        case modifiedOn = "modified_on"
        case allowedModes = "allowed_modes"
    }

    static func parseDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.date(from: raw)
    }
}

nonisolated struct IPRuleConfig: Codable, Sendable {
    let target: String
    let value: String
}
