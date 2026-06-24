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

/// POST /zones/{id}/purge_cache
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

nonisolated struct PurgeResult: Codable, Sendable {
    let id: String?
}
