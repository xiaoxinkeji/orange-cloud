//
//  ZoneSettingsModels.swift
//  Orange Cloud
//
//  Zone 设置（security_level / development_mode）与缓存清理。
//

import Foundation

/// GET/PATCH /zones/{id}/settings/{setting} 的 result
nonisolated struct ZoneSetting: Codable, Sendable {
    let id:    String?
    let value: String
}

nonisolated struct ZoneSettingUpdate: Codable, Sendable {
    let value: String
}

/// POST /zones/{id}/purge_cache —— 全量清理
nonisolated struct PurgeRequest: Codable, Sendable {
    let purgeEverything: Bool?
    let files: [String]?
    let tags: [String]?
    let hosts: [String]?

    init(purgeEverything: Bool) {
        self.purgeEverything = purgeEverything
        self.files = nil
        self.tags = nil
        self.hosts = nil
    }

    init(files: [String]) {
        self.purgeEverything = nil
        self.files = files
        self.tags = nil
        self.hosts = nil
    }

    init(tags: [String]) {
        self.purgeEverything = nil
        self.files = nil
        self.tags = tags
        self.hosts = nil
    }

    init(hosts: [String]) {
        self.purgeEverything = nil
        self.files = nil
        self.tags = nil
        self.hosts = hosts
    }

    enum CodingKeys: String, CodingKey {
        case purgeEverything = "purge_everything"
        case files, tags, hosts
    }
}

/// POST /zones/{id}/purge_cache —— 按单文件 URL 清理
/// （2025-04 起所有套餐可用，单次最多 30 个 URL）
nonisolated struct PurgeFilesRequest: Codable, Sendable {
    let files: [String]
}

/// POST /zones/{id}/purge_cache —— 按 URL 前缀清理（如 example.com/news），2025-04 起所有套餐可用
nonisolated struct PurgePrefixesRequest: Codable, Sendable {
    let prefixes: [String]
}

/// POST /zones/{id}/purge_cache —— 按主机名清理（如 assets.example.com），2025-04 起所有套餐可用
nonisolated struct PurgeHostsRequest: Codable, Sendable {
    let hosts: [String]
}

/// POST /zones/{id}/purge_cache —— 按 Cache-Tag 清理，2025-04 起所有套餐可用
nonisolated struct PurgeTagsRequest: Codable, Sendable {
    let tags: [String]
}

nonisolated struct PurgeResult: Codable, Sendable {
    let id: String?
}
