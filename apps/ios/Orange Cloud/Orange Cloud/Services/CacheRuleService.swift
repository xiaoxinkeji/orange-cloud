//
//  CacheRuleService.swift
//  Orange Cloud
//
//  读取 Cache Rules（精细化缓存策略）。
//

import Foundation

struct CacheRuleService {

    private let client: CFAPIClient

    init(client: CFAPIClient) {
        self.client = client
    }

    func listRules(zoneId: String) async throws -> [CacheRule] {
        let response: CFAPIResponse<CacheRuleset> = try await client.get(
            "zones/\(zoneId)/rulesets/phases/http_request_cache_settings/entrypoint"
        )
        guard response.success, let rules = response.result?.rules else {
            throw response.toAPIError()
        }
        return rules
    }
}
