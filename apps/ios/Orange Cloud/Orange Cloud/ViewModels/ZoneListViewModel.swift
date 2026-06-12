//
//  ZoneListViewModel.swift
//  Orange Cloud
//
//  拉取 Zone 列表并同步进 SwiftData 缓存，View 通过 @Query 渲染。
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class ZoneListViewModel {

    var isLoading = false
    var error: String?

    private let zoneService: ZoneService

    init(zoneService: ZoneService) {
        self.zoneService = zoneService
    }

    /// 从 API 刷新并 upsert 进缓存（共享逻辑见 CacheSync，含 Widget 快照与 Spotlight 索引）
    func refresh(accountId: String, accountName: String = "", context: ModelContext) async {
        isLoading = true
        error = nil
        do {
            let zones = try await zoneService.listZones(accountId: accountId)
            try CacheSync.syncZones(zones, accountId: accountId, accountName: accountName, context: context)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
