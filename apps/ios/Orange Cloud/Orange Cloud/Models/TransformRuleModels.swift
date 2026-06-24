//
//  TransformRuleModels.swift
//  Orange Cloud
//
//  Transform Rules：URL 改写、请求/响应头修改。
//

import Foundation

nonisolated struct TransformRuleset: Codable, Sendable {
    let id: String?
    let name: String?
    let rules: [TransformRule]?
}

nonisolated struct TransformRule: Codable, Identifiable, Sendable {
    let id: String?
    let enabled: Bool?
    let description: String?
    let action: String?
    let actionParameters: TransformActionParams?
    let expression: String?

    var uid: String { id ?? UUID().uuidString }

    var isURLRewrite: Bool { action == "rewrite" }
    var isResponseHeader: Bool { action == "rewrite_response_headers" }
    var isRequestHeader: Bool { action == "rewrite_request_headers" }

    var actionLabel: String {
        if isURLRewrite { return String(localized: "URL 改写") }
        if isResponseHeader { return String(localized: "响应头") }
        if isRequestHeader { return String(localized: "请求头") }
        return action ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case id, enabled, description, action, expression
        case actionParameters = "action_parameters"
    }
}

nonisolated struct TransformActionParams: Codable, Sendable {
    let uri: TransformURI?
    let headers: [String: TransformHeaderOp]?
}

nonisolated struct TransformURI: Codable, Sendable {
    let path: TransformURIPart?
    let query: TransformURIPart?
}

nonisolated struct TransformURIPart: Codable, Sendable {
    let expression: String?
    let value: String?
}

nonisolated struct TransformHeaderOp: Codable, Sendable {
    let operation: String?
    let value: String?
    let expression: String?

    var opLabel: String {
        switch operation {
        case "set":    String(localized: "设置")
        case "remove": String(localized: "删除")
        default:       operation ?? ""
        }
    }
}
