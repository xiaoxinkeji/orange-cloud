//
//  LoadBalancerService.swift
//  Orange Cloud
//
//  Cloudflare Load Balancing API：负载均衡器、源站池、健康检查。
//

import Foundation

struct LoadBalancerService {

    private let client: CFAPIClient

    init(client: CFAPIClient) {
        self.client = client
    }

    // MARK: - Load Balancers（zone 级）

    func listLoadBalancers(zoneId: String) async throws -> [LoadBalancer] {
        let response: CFAPIResponseArray<LoadBalancer> = try await client.get(
            "zones/\(zoneId)/load_balancers"
        )
        guard response.success else {
            throw response.toAPIError()
        }
        return response.result ?? []
    }

    func getLoadBalancer(zoneId: String, lbId: String) async throws -> LoadBalancer {
        let response: CFAPIResponse<LoadBalancer> = try await client.get(
            "zones/\(zoneId)/load_balancers/\(lbId)"
        )
        guard response.success, let lb = response.result else {
            throw response.toAPIError()
        }
        return lb
    }

    // MARK: - Pools（账号级）

    func listPools(accountId: String) async throws -> [LBPool] {
        let response: CFAPIResponseArray<LBPool> = try await client.get(
            "user/load_balancers/pools",
            queryItems: [URLQueryItem(name: "account.id", value: accountId)]
        )
        guard response.success else {
            throw response.toAPIError()
        }
        return response.result ?? []
    }

    func getPool(poolId: String) async throws -> LBPool {
        let response: CFAPIResponse<LBPool> = try await client.get(
            "user/load_balancers/pools/\(poolId)"
        )
        guard response.success, let pool = response.result else {
            throw response.toAPIError()
        }
        return pool
    }

    // MARK: - Monitors（账号级）

    func listMonitors(accountId: String) async throws -> [LBMonitor] {
        let response: CFAPIResponseArray<LBMonitor> = try await client.get(
            "user/load_balancers/monitors",
            queryItems: [URLQueryItem(name: "account.id", value: accountId)]
        )
        guard response.success else {
            throw response.toAPIError()
        }
        return response.result ?? []
    }

    func getMonitor(monitorId: String) async throws -> LBMonitor {
        let response: CFAPIResponse<LBMonitor> = try await client.get(
            "user/load_balancers/monitors/\(monitorId)"
        )
        guard response.success, let monitor = response.result else {
            throw response.toAPIError()
        }
        return monitor
    }
}
