//
//  FirewallRuleService.swift
//  Orange Cloud
//
//  IP 访问规则：列表查看。
//

import Foundation

struct FirewallRuleService {

    private let client: CFAPIClient

    init(client: CFAPIClient) {
        self.client = client
    }

    func listRules(zoneId: String) async throws -> [IPAccessRule] {
        let response: CFAPIResponseArray<IPAccessRule> = try await client.get(
            "zones/\(zoneId)/firewall/access_rules/rules",
            queryItems: [URLQueryItem(name: "per_page", value: "50")]
        )
        guard response.success else {
            throw response.toAPIError()
        }
        return response.result ?? []
    }
}
