//
//  BulkRedirectModels.swift
//  Orange Cloud
//
//  Bulk Redirects 模型：URL 转发规则列表。
//

import Foundation

nonisolated struct BulkRedirectList: Codable, Sendable {
    let id: String?
    let rules: [BulkRedirectRule]?
}

nonisolated struct BulkRedirectRule: Codable, Identifiable, Sendable {
    let ruleId: String?
    let enabled: Bool?
    let description: String?
    let actionParameters: BulkRedirectAction?

    var id: String { ruleId ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case ruleId = "id"
        case enabled, description
        case actionParameters = "action_parameters"
    }
}

nonisolated struct BulkRedirectAction: Codable, Sendable {
    let fromValue: String?
    let toValue: String?
    let statusCode: Int?
    let preserveQueryString: Bool?

    enum CodingKeys: String, CodingKey {
        case fromValue = "from_value"
        case toValue   = "to_value"
        case statusCode = "status_code"
        case preserveQueryString = "preserve_query_string"
    }

    var statusLabel: String {
        switch statusCode {
        case 301: String(localized: "301 永久")
        case 302: String(localized: "302 临时")
        case 307: String(localized: "307 临时")
        case 308: String(localized: "308 永久")
        default:  "\(statusCode ?? 0)"
        }
    }
}
