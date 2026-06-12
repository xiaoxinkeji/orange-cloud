//
//  TunnelWAFViewModels.swift
//  Orange Cloud
//
//  P5：Tunnel 列表与 WAF 自定义规则的 ViewModel。实时拉取，不进 SwiftData。
//

import Foundation
import Observation

@Observable
@MainActor
final class TunnelListViewModel {

    var tunnels: [Tunnel] = []
    var isLoading = false
    var error: String?

    private let service: TunnelService

    init(service: TunnelService) {
        self.service = service
    }

    func load(accountId: String) async {
        isLoading = true
        error = nil
        do {
            tunnels = try await service.listTunnels(accountId: accountId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

@Observable
@MainActor
final class WAFRulesViewModel {

    private(set) var ruleset: WAFRuleset?
    private(set) var loaded = false        // 区分"未加载"与"加载过但没有规则"
    var isLoading = false
    var error: String?
    var togglingRuleId: String?

    var rules: [WAFRule] { ruleset?.rules ?? [] }

    private let service: WAFService
    private let zoneId: String

    init(service: WAFService, zoneId: String) {
        self.service = service
        self.zoneId = zoneId
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            ruleset = try await service.customRuleset(zoneId: zoneId)
            loaded = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    /// 启停规则；失败时回滚由 ruleset 整体替换保证
    func toggle(rule: WAFRule, enabled: Bool) async {
        guard let rulesetId = ruleset?.id, togglingRuleId == nil else { return }
        togglingRuleId = rule.id
        error = nil
        do {
            ruleset = try await service.setRuleEnabled(
                zoneId: zoneId, rulesetId: rulesetId, ruleId: rule.id, enabled: enabled
            )
        } catch {
            self.error = error.localizedDescription
        }
        togglingRuleId = nil
    }

    /// 新建规则：已有规则集则追加，否则创建 entrypoint。成功返回 true。
    var isSaving = false

    func addRule(_ draft: WAFRuleCreate) async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            if let rulesetId = ruleset?.id {
                ruleset = try await service.addRule(zoneId: zoneId, rulesetId: rulesetId, rule: draft)
            } else {
                ruleset = try await service.createRuleset(zoneId: zoneId, rule: draft)
            }
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func delete(rule: WAFRule) async {
        guard let rulesetId = ruleset?.id else { return }
        error = nil
        do {
            try await service.deleteRule(zoneId: zoneId, rulesetId: rulesetId, ruleId: rule.id)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
