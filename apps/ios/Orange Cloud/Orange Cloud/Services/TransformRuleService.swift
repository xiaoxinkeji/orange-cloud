//
//  TransformRuleService.swift
//  Orange Cloud
//
//  读取 Transform Rules（URL 改写、请求头修改、响应头修改）。
//

import Foundation

struct TransformRuleService {

    private let client: CFAPIClient

    init(client: CFAPIClient) {
        self.client = client
    }

    /// 获取所有类型的 Transform Rules，合并返回
    func listRules(zoneId: String) async throws -> [TransformRule] {
        let phases: [(String, String)] = [
            ("URL 改写",    "http_request_transform"),
            ("请求头修改",  "http_request_late_transform"),
            ("响应头修改",  "http_response_headers_transform"),
        ]
        var all: [TransformRule] = []
        for (_, phase) in phases {
            let response: CFAPIResponse<TransformRuleset> = try await client.get(
                "zones/\(zoneId)/rulesets/phases/\(phase)/entrypoint"
            )
            if response.success, let rules = response.result?.rules {
                all.append(contentsOf: rules)
            }
        }
        return all
    }
}
