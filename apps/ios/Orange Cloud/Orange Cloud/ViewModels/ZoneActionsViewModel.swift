//
//  ZoneActionsViewModel.swift
//  Orange Cloud
//
//  Zone 详情页「操作」区：Under Attack / 开发模式开关 + 缓存清理。
//

import Foundation
import Observation

@Observable
@MainActor
final class ZoneActionsViewModel {

    private(set) var underAttack = false
    private(set) var devMode = false
    private(set) var alwaysUseHTTPS = false
    private(set) var autoHTTPSRewrites = false
    private(set) var sslMode: String = ""
    private(set) var settingsLoaded = false

    var isTogglingUnderAttack = false
    var isTogglingDevMode = false
    var isTogglingAlwaysHTTPS = false
    var isTogglingAutoHTTPS = false
    var isPurging = false
    var didPurge = false
    var error: String?

    private let service: ZoneSettingsService
    private let zoneId: String

    init(service: ZoneSettingsService, zoneId: String) {
        self.service = service
        self.zoneId = zoneId
    }

    func loadSettings() async {
        guard !settingsLoaded else { return }
        async let securityTask = service.getSetting(zoneId: zoneId, setting: "security_level")
        async let devTask = service.getSetting(zoneId: zoneId, setting: "development_mode")
        async let sslTask = service.getSetting(zoneId: zoneId, setting: "ssl")
        async let httpsTask = service.getSetting(zoneId: zoneId, setting: "always_use_https")
        async let rewritesTask = service.getSetting(zoneId: zoneId, setting: "automatic_https_rewrites")

        let security = try? await securityTask
        let dev = try? await devTask
        let ssl = try? await sslTask
        let https = try? await httpsTask
        let rewrites = try? await rewritesTask

        guard security != nil || dev != nil || ssl != nil else { return }

        underAttack = security == "under_attack"
        devMode = dev == "on"
        sslMode = ssl ?? ""
        alwaysUseHTTPS = https == "on"
        autoHTTPSRewrites = rewrites == "on"
        settingsLoaded = true
    }

    func setUnderAttack(_ on: Bool) async {
        guard !isTogglingUnderAttack else { return }
        isTogglingUnderAttack = true
        error = nil
        do {
            // 关闭时恢复为 medium（Cloudflare 默认安全级别；API 不记录开启前的旧值）
            let value = try await service.setSetting(
                zoneId: zoneId, setting: "security_level",
                value: on ? "under_attack" : "medium"
            )
            underAttack = value == "under_attack"
        } catch {
            self.error = error.localizedDescription
        }
        isTogglingUnderAttack = false
    }

    func setDevMode(_ on: Bool) async {
        guard !isTogglingDevMode else { return }
        isTogglingDevMode = true
        error = nil
        do {
            let value = try await service.setSetting(
                zoneId: zoneId, setting: "development_mode",
                value: on ? "on" : "off"
            )
            devMode = value == "on"
        } catch {
            self.error = error.localizedDescription
        }
        isTogglingDevMode = false
    }

    func purgeCache() async {
        guard !isPurging else { return }
        isPurging = true
        error = nil
        do {
            try await service.purgeAllCache(zoneId: zoneId)
            didPurge.toggle()
        } catch {
            self.error = error.localizedDescription
        }
        isPurging = false
    }

    func setAlwaysUseHTTPS(_ on: Bool) async {
        guard !isTogglingAlwaysHTTPS else { return }
        isTogglingAlwaysHTTPS = true
        error = nil
        do {
            let value = try await service.setSetting(
                zoneId: zoneId, setting: "always_use_https",
                value: on ? "on" : "off"
            )
            alwaysUseHTTPS = value == "on"
        } catch {
            self.error = error.localizedDescription
        }
        isTogglingAlwaysHTTPS = false
    }

    func setAutoHTTPSRewrites(_ on: Bool) async {
        guard !isTogglingAutoHTTPS else { return }
        isTogglingAutoHTTPS = true
        error = nil
        do {
            let value = try await service.setSetting(
                zoneId: zoneId, setting: "automatic_https_rewrites",
                value: on ? "on" : "off"
            )
            autoHTTPSRewrites = value == "on"
        } catch {
            self.error = error.localizedDescription
        }
        isTogglingAutoHTTPS = false
    }

    var sslModeLabel: String {
        switch sslMode {
        case "off":     String(localized: "关闭（仅 HTTP）")
        case "flexible": String(localized: "灵活")
        case "full":    String(localized: "严格")
        case "strict":  String(localized: "完全（严格）")
        default:        sslMode.isEmpty ? String(localized: "未知") : sslMode
        }
    }
}
