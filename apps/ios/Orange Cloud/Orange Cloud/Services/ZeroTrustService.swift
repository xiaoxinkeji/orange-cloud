//
//  ZeroTrustService.swift
//  Orange Cloud
//
//  Zero Trust 只读：Access 应用列表 + Gateway 策略列表（账号级）。
//

import Foundation

struct ZeroTrustService {

    private let client: CFAPIClient

    init(client: CFAPIClient) {
        self.client = client
    }

    /// Access 应用列表（access.read）
    func accessApps(accountId: String) async throws -> [AccessApp] {
        let response: CFAPIResponseArray<AccessApp> = try await client.get(
            "accounts/\(accountId)/access/apps"
        )
        guard response.success else {
            throw response.toAPIError()
        }
        return response.result ?? []
    }

    /// Gateway 策略列表（teams.read）
    func gatewayRules(accountId: String) async throws -> [GatewayRule] {
        let response: CFAPIResponseArray<GatewayRule> = try await client.get(
            "accounts/\(accountId)/gateway/rules"
        )
        guard response.success else {
            throw response.toAPIError()
        }
        return response.result ?? []
    }
}
