//
//  ZoneActionsViewModel.swift
//  Orange Cloud
//
//  Zone 设置：安全开关、SSL/TLS、网络优化、缓存控制。
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

    private(set) var http2Enabled = true
    private(set) var http3Enabled = true
    private(set) var websocketsEnabled = true
    private(set) var ipv6Enabled = true
    private(set) var brotliEnabled = true
    private(set) var earlyHintsEnabled = false
    private(set) var alwaysOnlineEnabled = false
    private(set) var cachingLevel: String = ""

    private(set) var settingsLoaded = false
    private(set) var networkSettingsLoaded = false

    var isTogglingUnderAttack = false
    var isTogglingDevMode = false
    var isTogglingAlwaysHTTPS = false
    var isTogglingAutoHTTPS = false
    var isTogglingNetwork = false
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

    func loadNetworkSettings() async {
        guard !networkSettingsLoaded else { return }
        async let h2Task = service.getSetting(zoneId: zoneId, setting: "http2")
        async let h3Task = service.getSetting(zoneId: zoneId, setting: "http3")
        async let wsTask = service.getSetting(zoneId: zoneId, setting: "websockets")
        async let v6Task = service.getSetting(zoneId: zoneId, setting: "ipv6")
        async let brTask = service.getSetting(zoneId: zoneId, setting: "brotli")
        async let ehTask = service.getSetting(zoneId: zoneId, setting: "early_hints")
        async let aoTask = service.getSetting(zoneId: zoneId, setting: "always_online")
        async let clTask = service.getSetting(zoneId: zoneId, setting: "caching_level")

        let h2  = try? await h2Task
        let h3  = try? await h3Task
        let ws  = try? await wsTask
        let v6  = try? await v6Task
        let br  = try? await brTask
        let eh  = try? await ehTask
        let ao  = try? await aoTask
        let cl  = try? await clTask

        guard h2 != nil || h3 != nil || ws != nil else { return }

        http2Enabled = h2 == "on"
        http3Enabled = h3 == "on"
        websocketsEnabled = ws == "on"
        ipv6Enabled = v6 == "on"
        brotliEnabled = br == "on"
        earlyHintsEnabled = eh == "on"
        alwaysOnlineEnabled = ao == "on"
        cachingLevel = cl ?? ""
        networkSettingsLoaded = true
    }

    func toggleSetting(_ setting: String, current: Bool) async {
        guard !isTogglingNetwork else { return }
        isTogglingNetwork = true
        error = nil
        do {
            let on = !current
            let value = try await service.setSetting(
                zoneId: zoneId, setting: setting,
                value: on ? "on" : "off"
            )
            let result = value == "on"
            switch setting {
            case "http2":                     http2Enabled = result
            case "http3":                     http3Enabled = result
            case "websockets":                websocketsEnabled = result
            case "ipv6":                      ipv6Enabled = result
            case "brotli":                    brotliEnabled = result
            case "early_hints":               earlyHintsEnabled = result
            case "always_online":             alwaysOnlineEnabled = result
            default:                          break
            }
        } catch {
            self.error = error.localizedDescription
        }
        isTogglingNetwork = false
    }

    func setCachingLevel(_ level: String) async {
        guard !isTogglingNetwork else { return }
        isTogglingNetwork = true
        error = nil
        do {
            let value = try await service.setSetting(
                zoneId: zoneId, setting: "caching_level",
                value: level
            )
            cachingLevel = value
        } catch {
            self.error = error.localizedDescription
        }
        isTogglingNetwork = false
    }

    func setUnderAttack(_ on: Bool) async {
        guard !isTogglingUnderAttack else { return }
        isTogglingUnderAttack = true
        error = nil
        do {
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

    var cachingLevelLabel: String {
        switch cachingLevel {
        case "standard":   String(localized: "标准")
        case "no_query":   String(localized: "忽略查询字符串")
        case "aggressive": String(localized: "激进")
        default:          cachingLevel.isEmpty ? String(localized: "—") : cachingLevel
        }
    }
}
