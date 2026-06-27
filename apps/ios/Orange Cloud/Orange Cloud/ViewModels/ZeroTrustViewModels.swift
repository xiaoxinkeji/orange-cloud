//
//  ZeroTrustViewModels.swift
//  Orange Cloud
//
//  Zero Trust 只读：Access 应用 / Gateway 策略列表加载。
//

import Foundation
import Observation

@Observable
@MainActor
final class AccessAppsViewModel {

    private(set) var apps: [AccessApp] = []
    private(set) var loaded = false
    var isLoading = false
    var error: String?

    private let service: ZeroTrustService
    private let accountId: String?

    init(service: ZeroTrustService, accountId: String?) {
        self.service = service
        self.accountId = accountId
    }

    func load() async {
        guard !isLoading, let accountId else { return }
        isLoading = true
        error = nil
        do {
            apps = try await service.accessApps(accountId: accountId)
            loaded = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

@Observable
@MainActor
final class GatewayRulesViewModel {

    private(set) var rules: [GatewayRule] = []
    private(set) var loaded = false
    var isLoading = false
    var error: String?

    private let service: ZeroTrustService
    private let accountId: String?

    init(service: ZeroTrustService, accountId: String?) {
        self.service = service
        self.accountId = accountId
    }

    func load() async {
        guard !isLoading, let accountId else { return }
        isLoading = true
        error = nil
        do {
            rules = try await service.gatewayRules(accountId: accountId)
            loaded = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
