//
//  EntitlementStore.swift
//  Orange Cloud
//
//  StoreKit 2 内购管理：加载商品、监听交易更新、验证购买、恢复购买。
//  自签编译（定义 OPENSOURCE_UNLOCKED）时跳过 StoreKit，isPro 始终为 true。
//

import Foundation
#if !OPENSOURCE_UNLOCKED
import StoreKit
#endif

// MARK: - Protocol

protocol EntitlementProviding: Observable {
    var isPro: Bool { get }
    func start()
    func purchase() async throws
    func restore() async throws
}

// MARK: - EntitlementStore

@Observable
@MainActor
final class EntitlementStore: EntitlementProviding {

    static let shared = EntitlementStore()

    // MARK: - Product IDs

    enum ProductID {
        static let lifetime = "pro.lifetime"
        static let monthly  = "pro.monthly"
        static let yearly   = "pro.yearly"
        static let all: Set<String> = [lifetime, monthly, yearly]
    }

    // MARK: - Observable State

    /// 当前已解锁 Pro（计算属性，基于活跃权益）
    var isPro: Bool {
        #if OPENSOURCE_UNLOCKED
        return true
        #else
        return !activeEntitlements.isEmpty
        #endif
    }

    #if !OPENSOURCE_UNLOCKED
    /// App Store 加载到的可售商品
    var products: [Product] = []
    #endif

    /// 是否正在加载商品
    var isLoadingProducts: Bool = false

    /// 当前正在购买的商品 ID
    var purchasingProductID: String? = nil

    /// 购买/恢复过程中出现的错误信息
    var errorMessage: String? = nil

    // MARK: - Private State

    #if !OPENSOURCE_UNLOCKED
    /// 已验证的活跃权益（productID 集合）
    private var activeEntitlements: Set<String> = []

    /// Transaction.updates 监听任务
    private var transactionListenerTask: Task<Void, Never>? = nil
    #endif

    // MARK: - Lifecycle

    private init() {}

    deinit {
        #if !OPENSOURCE_UNLOCKED
        transactionListenerTask?.cancel()
        #endif
    }

    // MARK: - Public API

    /// 启动：加载商品 + 检查已有权益 + 开始监听交易更新
    func start() {
        #if OPENSOURCE_UNLOCKED
        // 自签构建：无需任何 StoreKit 操作
        #else
        transactionListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await checkCurrentEntitlements()
        }
        #endif
    }

    /// 购买：弹出系统购买面板并验证交易（取首个可用商品）
    func purchase() async throws {
        #if OPENSOURCE_UNLOCKED
        // 自签构建：无需购买
        #else
        guard let product = products.first ?? pickPreferredProduct() else {
            let error = EntitlementError.noProductsAvailable
            errorMessage = error.localizedDescription
            throw error
        }
        try await purchase(product: product)
        #endif
    }

    #if !OPENSOURCE_UNLOCKED
    /// 购买指定商品
    func purchase(product: Product) async throws {
        purchasingProductID = product.id
        errorMessage = nil
        defer { purchasingProductID = nil }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await checkCurrentEntitlements()

        case .userCancelled:
            break

        case .pending:
            // 等待家长审批等场景，交易尚未完成
            break

        @unknown default:
            break
        }
    }
    #endif

    /// 恢复购买
    func restore() async throws {
        #if OPENSOURCE_UNLOCKED
        // 自签构建：无需恢复
        #else
        errorMessage = nil
        try await AppStore.sync()
        await checkCurrentEntitlements()
        #endif
    }

    #if !OPENSOURCE_UNLOCKED
    /// 按 ID 获取商品（供 PaywallView 按类型展示）
    func product(for id: String) -> Product? {
        return products.first { $0.id == id }
    }
    #endif

    /// Pro 商品 ID 列表（供 PaywallView 遍历）
    var productIDs: [String] {
        [ProductID.lifetime, ProductID.yearly, ProductID.monthly]
    }

    // MARK: - Private

    #if !OPENSOURCE_UNLOCKED

    /// 从 App Store 加载商品
    private func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: ProductID.all)
            // 按固定顺序排序：lifetime > yearly > monthly
            let order = [ProductID.lifetime, ProductID.yearly, ProductID.monthly]
            products.sort { a, b in
                (order.firstIndex(of: a.id) ?? Int.max) < (order.firstIndex(of: b.id) ?? Int.max)
            }
        } catch {
            errorMessage = "无法加载商品：\(error.localizedDescription)"
        }
    }

    /// 检查当前已有的活跃权益
    private func checkCurrentEntitlements() async {
        var entitlements: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                entitlements.insert(transaction.productID)
            }
        }
        activeEntitlements = entitlements
    }

    /// 持续监听 StoreKit 交易更新（退款、退款争议、跨设备同步等）
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                await MainActor.run {
                    guard let self else { return }
                    do {
                        let transaction = try self.checkVerified(result)
                        Task {
                            await transaction.finish()
                            await self.checkCurrentEntitlements()
                        }
                    } catch {
                        self.errorMessage = "交易验证失败：\(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// 验证交易签名
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    /// 当 products 数组为空时尝试按优先级取一个
    private func pickPreferredProduct() -> Product? {
        let preferred = [ProductID.lifetime, ProductID.yearly, ProductID.monthly]
        for id in preferred {
            if let p = products.first(where: { $0.id == id }) { return p }
        }
        return products.first
    }

    #endif
}

// MARK: - Errors

enum EntitlementError: LocalizedError {
    case noProductsAvailable
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .noProductsAvailable:
            return "没有可购买的商品"
        case .failedVerification:
            return "交易验证失败"
        }
    }
}
