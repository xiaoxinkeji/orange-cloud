//
//  ZoneActionsViewModel.swift
//  Orange Cloud
//
//  Zone 详情页「操作」区：Under Attack / 开发模式开关 + 缓存清理 + 网络/缓存设置。
//

import Foundation
import Observation

@Observable
@MainActor
final class ZoneActionsViewModel {

    private(set) var underAttack = false
    private(set) var devMode = false
    private(set) var settingsLoaded = false

    // SSL / HTTPS 设置
    private(set) var alwaysUseHTTPS = false
    private(set) var autoHTTPSRewrites = false
    private(set) var sslMode = ""

    var isTogglingUnderAttack = false
    var isTogglingDevMode = false
    var isTogglingAlwaysHTTPS = false
    var isTogglingAutoHTTPS = false
    var isPurging = false
    var didPurge = false       // sensoryFeedback / 提示触发器
    var error: String?

    // 网络设置
    private(set) var http2Enabled = false
    private(set) var http3Enabled = false
    private(set) var websocketsEnabled = false
    private(set) var ipv6Enabled = false
    private(set) var brotliEnabled = false
    private(set) var earlyHintsEnabled = false
    private(set) var alwaysOnlineEnabled = false
    var isTogglingNetwork = false

    // 缓存级别
    private(set) var cachingLevel = ""

    var sslModeLabel: String {
        switch sslMode {
        case "off":      String(localized: "关闭")
        case "flexible": String(localized: "灵活")
        case "full":     String(localized: "完整")
        case "strict":   String(localized: "完整（严格）")
        default:         sslMode
        }
    }

    var cachingLevelLabel: String {
        switch cachingLevel {
        case "standard":  String(localized: "标准")
        case "no_query":  String(localized: "忽略查询")
        case "aggressive": String(localized: "激进")
        default:          cachingLevel
        }
    }

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
        async let httpsTask = service.getSetting(zoneId: zoneId, setting: "always_use_https")
        async let rewriteTask = service.getSetting(zoneId: zoneId, setting: "automatic_https_rewrites")
        async let sslTask = service.getSetting(zoneId: zoneId, setting: "ssl")
        // 读不到（无 zone-settings.read 等）就保持未加载态，开关显示为锁定
        guard let security = try? await securityTask, let dev = try? await devTask else { return }
        underAttack = security == "under_attack"
        devMode = dev == "on"
        if let https = try? await httpsTask {
            alwaysUseHTTPS = https == "on"
        }
        if let rewrite = try? await rewriteTask {
            autoHTTPSRewrites = rewrite == "on"
        }
        if let ssl = try? await sslTask {
            sslMode = ssl
        }
        settingsLoaded = true
    }

    func loadNetworkSettings() async {
        async let http2Task = service.getSetting(zoneId: zoneId, setting: "http2")
        async let http3Task = service.getSetting(zoneId: zoneId, setting: "http3")
        async let wsTask = service.getSetting(zoneId: zoneId, setting: "websockets")
        async let ipv6Task = service.getSetting(zoneId: zoneId, setting: "ipv6")
        async let brotliTask = service.getSetting(zoneId: zoneId, setting: "brotli")
        async let hintsTask = service.getSetting(zoneId: zoneId, setting: "early_hints")
        async let onlineTask = service.getSetting(zoneId: zoneId, setting: "always_online")
        async let cacheTask = service.getSetting(zoneId: zoneId, setting: "caching_level")

        if let v = try? await http2Task { http2Enabled = v == "on" }
        if let v = try? await http3Task { http3Enabled = v == "on" }
        if let v = try? await wsTask { websocketsEnabled = v == "on" }
        if let v = try? await ipv6Task { ipv6Enabled = v == "on" }
        if let v = try? await brotliTask { brotliEnabled = v == "on" }
        if let v = try? await hintsTask { earlyHintsEnabled = v == "on" }
        if let v = try? await onlineTask { alwaysOnlineEnabled = v == "on" }
        if let v = try? await cacheTask { cachingLevel = v }
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

    /// 通用网络设置开关（on/off 类）
    func toggleSetting(_ setting: String, current: Bool) async {
        guard !isTogglingNetwork else { return }
        isTogglingNetwork = true
        error = nil
        do {
            let value = try await service.setSetting(
                zoneId: zoneId, setting: setting,
                value: current ? "off" : "on"
            )
            let isOn = value == "on"
            switch setting {
            case "http2":         http2Enabled = isOn
            case "http3":         http3Enabled = isOn
            case "websockets":    websocketsEnabled = isOn
            case "ipv6":          ipv6Enabled = isOn
            case "brotli":        brotliEnabled = isOn
            case "early_hints":   earlyHintsEnabled = isOn
            case "always_online": alwaysOnlineEnabled = isOn
            default: break
            }
        } catch {
            self.error = error.localizedDescription
        }
        isTogglingNetwork = false
    }

    func setCachingLevel(_ level: String) async {
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

    /// 按 URL 清理缓存（单文件 purge，调用方负责限制 ≤ 30 个 URL）
    func purgeURLs(_ urls: [String]) async {
        await runPurge(urls) { try await service.purgeFiles(zoneId: zoneId, urls: $0) }
    }

    /// 按 URL 前缀清理缓存（调用方负责限制 ≤ 30 个）
    func purgePrefixes(_ prefixes: [String]) async {
        await runPurge(prefixes) { try await service.purgePrefixes(zoneId: zoneId, prefixes: $0) }
    }

    /// 按主机名清理缓存（调用方负责限制 ≤ 30 个）
    func purgeHosts(_ hosts: [String]) async {
        await runPurge(hosts) { try await service.purgeHosts(zoneId: zoneId, hosts: $0) }
    }

    /// 按 Cache-Tag 清理缓存（调用方负责限制 ≤ 30 个）
    func purgeTags(_ tags: [String]) async {
        await runPurge(tags) { try await service.purgeTags(zoneId: zoneId, tags: $0) }
    }

    /// 缓存清理统一执行：去重并发、清空错误、成功翻 didPurge 触发反馈
    private func runPurge(_ items: [String], _ op: ([String]) async throws -> Void) async {
        guard !isPurging, !items.isEmpty else { return }
        isPurging = true
        error = nil
        do {
            try await op(items)
            didPurge.toggle()
        } catch {
            self.error = error.localizedDescription
        }
        isPurging = false
    }
}
