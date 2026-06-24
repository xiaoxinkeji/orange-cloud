//
//  BulkRedirectService.swift
//  Orange Cloud
//
//  Bulk Redirects：URL 转发规则列表。
//

import Foundation

struct BulkRedirectService {

    private let client: CFAPIClient

    init(client: CFAPIClient) {
        self.client = client
    }

    func listRedirects(zoneId: String) async throws -> [BulkRedirectRule] {
        let response: CFAPIResponse<BulkRedirectList> = try await client.get(
            "zones/\(zoneId)/rulesets/phases/http_request_redirect/entrypoint"
        )
        guard response.success, let list = response.result else {
            throw response.toAPIError()
        }
        return list.rules ?? []
    }
}
