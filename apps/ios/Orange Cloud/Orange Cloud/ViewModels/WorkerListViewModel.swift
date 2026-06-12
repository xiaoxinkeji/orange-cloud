//
//  WorkerListViewModel.swift
//  Orange Cloud
//
//  拉取 Workers 脚本列表并同步进 SwiftData 缓存，View 通过 @Query 渲染。
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class WorkerListViewModel {

    var isLoading = false
    var error: String?

    private let workerService: WorkerService

    init(workerService: WorkerService) {
        self.workerService = workerService
    }

    /// 从 API 刷新并 upsert 进缓存（共享逻辑见 CacheSync，仅限当前账号）
    func refresh(accountId: String, context: ModelContext) async {
        isLoading = true
        error = nil
        do {
            let scripts = try await workerService.listScripts(accountId: accountId)
            try CacheSync.syncWorkers(scripts, accountId: accountId, context: context)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
