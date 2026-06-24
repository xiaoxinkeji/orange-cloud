//
//  EntitlementStore.swift
//  Orange Cloud
//
//  自签编译构建默认全功能解锁。isPro 始终为 true，不依赖 StoreKit。
//

import Foundation

@Observable
@MainActor
final class EntitlementStore {

    static let shared = EntitlementStore()

    var isPro: Bool { true }

    func start() {}
}
