//
//  CacheModels.swift
//  Orange Cloud
//
//  SwiftData 本地缓存：View 通过 @Query 读取，ViewModel 刷新 API 后写入，离线可读。
//

import Foundation
import SwiftData

@Model
final class CachedZone {
    @Attribute(.unique) var id: String
    var name:        String
    var status:      String
    var planName:    String
    var nameServers: [String]
    var accountId:   String
    var updatedAt:   Date
    var pinned:      Bool = false    // 固定到 Dashboard 首页（用户手动控制，刷新不重置）

    init(from zone: Zone, accountId: String) {
        self.id          = zone.id
        self.name        = zone.name
        self.status      = zone.status
        self.planName    = zone.plan?.name ?? "—"
        self.nameServers = zone.nameServers ?? []
        self.accountId   = accountId
        self.updatedAt   = Date()
    }

    func update(from zone: Zone) {
        name        = zone.name
        status      = zone.status
        planName    = zone.plan?.name ?? "—"
        nameServers = zone.nameServers ?? []
        updatedAt   = Date()
    }
}

@Model
final class CachedWorkerScript {
    // 脚本名只在账号内唯一，全局唯一键用 accountId/scriptId 复合
    @Attribute(.unique) var key: String
    var id:         String          // 脚本名
    var accountId:  String
    var createdOn:  String?
    var modifiedOn: String?
    var usageModel: String?
    var handlers:   [String]
    var logpush:    Bool
    var updatedAt:  Date

    init(from script: WorkerScript, accountId: String) {
        self.key        = "\(accountId)/\(script.id)"
        self.id         = script.id
        self.accountId  = accountId
        self.createdOn  = script.createdOn
        self.modifiedOn = script.modifiedOn
        self.usageModel = script.usageModel
        self.handlers   = script.handlers ?? []
        self.logpush    = script.logpush ?? false
        self.updatedAt  = Date()
    }

    func update(from script: WorkerScript) {
        createdOn  = script.createdOn
        modifiedOn = script.modifiedOn
        usageModel = script.usageModel
        handlers   = script.handlers ?? []
        logpush    = script.logpush ?? false
        updatedAt  = Date()
    }
}

@Model
final class CachedDNSRecord {
    @Attribute(.unique) var id: String
    var type:      String
    var name:      String
    var content:   String
    var proxied:   Bool
    var ttl:       Int
    var priority:  Int?
    var comment:   String?
    var zoneId:    String
    var updatedAt: Date

    init(from record: DNSRecord, zoneId: String) {
        self.id        = record.id
        self.type      = record.type
        self.name      = record.name
        self.content   = record.content
        self.proxied   = record.isProxied
        self.ttl       = record.ttl
        self.priority  = record.priority
        self.comment   = record.comment
        self.zoneId    = zoneId
        self.updatedAt = Date()
    }

    func update(from record: DNSRecord) {
        type      = record.type
        name      = record.name
        content   = record.content
        proxied   = record.isProxied
        ttl       = record.ttl
        priority  = record.priority
        comment   = record.comment
        updatedAt = Date()
    }
}
