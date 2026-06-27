//
//  ZeroTrustModels.swift
//  Orange Cloud
//
//  Zero Trust 只读：Access 应用（access.read）+ Gateway 策略（teams.read）。
//  GET /accounts/{id}/access/apps、GET /accounts/{id}/gateway/rules
//

import Foundation

/// Access 应用
nonisolated struct AccessApp: Codable, Identifiable, Sendable {
    let id:     String
    let name:   String?
    let domain: String?
    let type:   String?

    /// 应用类型可读名
    var typeLabel: String {
        switch type ?? "" {
        case "self_hosted":  String(localized: "自托管")
        case "saas":         "SaaS"
        case "ssh":          "SSH"
        case "vnc":          "VNC"
        case "app_launcher": String(localized: "应用启动台")
        case "warp":         "WARP"
        case "bookmark":     String(localized: "书签")
        case "dash_sso":     "Dash SSO"
        case "":             String(localized: "应用")
        case let other:      other
        }
    }
}

/// Gateway 策略（DNS / HTTP / Network）
nonisolated struct GatewayRule: Codable, Identifiable, Sendable {
    let id:          String
    let name:        String?
    let description: String?
    let action:      String?
    let enabled:     Bool?
    let precedence:  Int?
    let filters:     [String]?

    var isEnabled: Bool { enabled ?? false }

    /// 策略类型徽章（来自 filters）
    var kindLabel: String {
        guard let f = filters?.first else { return "Gateway" }
        switch f {
        case "dns":            return "DNS"
        case "http":           return "HTTP"
        case "l4":             return String(localized: "网络")
        case "egress":         return String(localized: "出口")
        case "resolver":       return String(localized: "解析器")
        default:               return f.uppercased()
        }
    }

    /// 动作可读名（常见值，其余原样）
    var actionLabel: String {
        switch action {
        case "allow":           String(localized: "允许")
        case "block":           String(localized: "阻止")
        case "isolate":         String(localized: "隔离")
        case "override":        String(localized: "覆盖")
        case "safesearch":      String(localized: "安全搜索")
        case "off":             String(localized: "关闭")
        case "on":              String(localized: "开启")
        case "do_not_inspect":  String(localized: "不检查")
        case "noscan":          String(localized: "不扫描")
        case let other?:        other
        case nil:               "—"
        }
    }
}
