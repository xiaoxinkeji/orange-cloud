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

    func createScript(accountId: String, name: String, context: ModelContext) async -> Bool {
        isLoading = true
        error = nil
        do {
            let boilerplate = """
            export default {
              async fetch(request, env, ctx) {
                return new Response("Hello from \\(request.url)");
              }
            }
            """
            let script = try await workerService.createScript(
                accountId: accountId, scriptName: name, content: boilerplate
            )
            try CacheSync.syncWorkers([script], accountId: accountId, context: context)
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func deleteScript(accountId: String, name: String, context: ModelContext) async {
        isLoading = true
        error = nil
        do {
            try await workerService.deleteScript(accountId: accountId, scriptName: name)
            try CacheSync.removeWorker(name: name, accountId: accountId, context: context)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
