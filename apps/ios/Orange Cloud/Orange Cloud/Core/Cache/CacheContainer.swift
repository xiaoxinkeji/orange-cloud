//
//  CacheContainer.swift
//  Orange Cloud
//
//  全局共享的 SwiftData 容器：App 主界面与 App Intents 共用同一存储。
//

import Foundation
import SwiftData

nonisolated enum CacheContainer {

    static let shared: ModelContainer = {
        let schema = Schema([
            CachedZone.self,
            CachedDNSRecord.self,
            CachedWorkerScript.self,
        ])
        // cloudKitDatabase 必须显式 .none：App 带 iCloud entitlement 时 .automatic 会
        // 强制开启 CloudKit 同步，而 CloudKit 不允许非可选属性和 @Attribute(.unique)。
        // 缓存数据本就按账号实时拉取，无需跨设备同步。
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
// 持久化容器创建失败时回退到纯内存模式，避免 crash。
            // 常见原因：磁盘空间不足、iCloud 容器权限被撤销。
            let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            guard let container = try? ModelContainer(for: schema, configurations: [memory])
            else {
                fatalError("Could not create ModelContainer (persistent or in-memory): \(error)")
            }
            return container
        }
    }()

    /// 删除磁盘上的 SwiftData 存储文件（含 -wal / -shm 旁文件），供损坏后清库重建。
    private static func destroyStoreFiles(at storeURL: URL) {
        let fm = FileManager.default
        let dir = storeURL.deletingLastPathComponent()
        let name = storeURL.lastPathComponent          // 默认为 "default.store"
        for suffix in ["", "-wal", "-shm"] {
            try? fm.removeItem(at: dir.appendingPathComponent(name + suffix))
        }
    }
}
