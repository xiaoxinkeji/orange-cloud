//
//  ZoneSettingsService.swift
//  Orange Cloud
//
//  Zone 设置读写（Under Attack / 开发模式）+ 全量缓存清理。
//

import Foundation

struct ZoneSettingsService {

    private let client: CFAPIClient

    init(client: CFAPIClient) {
        self.client = client
    }

    /// 读单项设置的当前值（如 security_level → "medium"，development_mode → "on"/"off"）
    func getSetting(zoneId: String, setting: String) async throws -> String {
        let response: CFAPIResponse<ZoneSetting> = try await client.get(
            "zones/\(zoneId)/settings/\(setting)"
        )
        guard response.success, let result = response.result else {
            throw response.toAPIError()
        }
        return result.value
    }

    /// 写单项设置，返回生效后的值
    func setSetting(zoneId: String, setting: String, value: String) async throws -> String {
        let response: CFAPIResponse<ZoneSetting> = try await client.patch(
            "zones/\(zoneId)/settings/\(setting)",
            body: ZoneSettingUpdate(value: value)
        )
        guard response.success, let result = response.result else {
            throw response.toAPIError()
        }
        return result.value
    }

    /// 清空该 Zone 在边缘的全部缓存
    func purgeAllCache(zoneId: String) async throws {
        let response: CFAPIResponse<PurgeResult> = try await client.post(
            "zones/\(zoneId)/purge_cache",
            body: PurgeRequest(purgeEverything: true)
        )
        guard response.success else {
            throw response.toAPIError()
        }
    }

    /// 按 URL 清除缓存
    func purgeByURL(zoneId: String, urls: [String]) async throws -> PurgeResult {
        let response: CFAPIResponse<PurgeResult> = try await client.post(
            "zones/\(zoneId)/purge_cache",
            body: PurgeRequest(files: urls)
        )
        guard response.success, let result = response.result else {
            throw response.toAPIError()
        }
        return result
    }

    /// 按 Tag 清除缓存
    func purgeByTag(zoneId: String, tags: [String]) async throws -> PurgeResult {
        let response: CFAPIResponse<PurgeResult> = try await client.post(
            "zones/\(zoneId)/purge_cache",
            body: PurgeRequest(tags: tags)
        )
        guard response.success, let result = response.result else {
            throw response.toAPIError()
        }
        return result
    }
}
