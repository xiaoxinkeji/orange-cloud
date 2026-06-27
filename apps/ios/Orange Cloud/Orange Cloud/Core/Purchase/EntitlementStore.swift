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

// MARK: - Private

#if !OPENSOURCE_UNLOCKED
/// Wrapper to hold a Task reference without @Observable macro tracking.
private final class _TaskHolder: @unchecked Sendable {
    var task: Task<Void, Never>?
    init() {}
    deinit { task?.cancel() }
}
#endif

// MARK: - EntitlementStore

@Observable
@MainActor
final class EntitlementStore: EntitlementProviding {

    static let shared = EntitlementStore()

    nonisolated enum ProductID {
        static let monthly  = "jiamin.chen.orange_cloud.pro.monthly"
        static let yearly   = "jiamin.chen.orange_cloud.pro.yearly"
        static let lifetime = "jiamin.chen.orange_cloud.pro.lifetime"
        /// 付费墙展示顺序：年度（主推）→ 月度 → 买断
        static let all = [yearly, monthly, lifetime]
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

    /// 是否拥有买断权益
    private var hasLifetime: Bool = false

    /// Transaction.updates 监听任务（通过 wrapper 持有，避免 @Observable 宏冲突）
    private let _taskHolder = _TaskHolder()
    #endif

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Public API

    /// 启动：加载商品 + 检查已有权益 + 开始监听交易更新
    func start() {
        #if OPENSOURCE_UNLOCKED
        // 自签构建：无需任何 StoreKit 操作
        #else
        _taskHolder.task = listenForTransactions()
        Task {
            await loadProducts()
            await checkCurrentEntitlements()
        }
        #endif
    }

    func loadProducts() async {
        #if !OPENSOURCE_UNLOCKED
        guard products.isEmpty, !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: ProductID.all)
            products = ProductID.all.compactMap { id in loaded.first { $0.id == id } }
            if products.isEmpty {
                // 不抛错但结果为空：StoreKit 配置文件解析失败或商品 ID 不匹配
                AppLog.purchase.error("Product.products(for:) 返回空结果，请求的 ID：\(ProductID.all.joined(separator: ", "))")
                errorMessage = String(localized: "无法加载商品信息，请稍后再试。")
            } else {
                AppLog.purchase.info("已加载 \(self.products.count) 个商品")
            }
        } catch {
            AppLog.purchase.error("Product.products(for:) 失败：\(String(describing: error))")
            errorMessage = String(localized: "无法加载商品信息，请稍后再试。")
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
            if case .verified(let transaction) = verification {
                await transaction.finish()
                await refreshEntitlements()
                AppLog.purchase.notice("purchase verified: \(transaction.productID)")
            } else {
                AppLog.purchase.error("purchase result unverified")
                errorMessage = String(localized: "购买凭证校验失败，请尝试恢复购买。")
            }
        case .userCancelled, .pending:
            AppLog.purchase.info("purchase userCancelled/pending")
            break

        case .pending:
            // 等待家长审批等场景，交易尚未完成
            break

        @unknown default:
            break
        }
    }
    #endif

    func restorePurchases() async {
        #if !OPENSOURCE_UNLOCKED
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            AppLog.purchase.notice("restorePurchases synced, pro=\(isPro)")
        } catch {
            AppLog.purchase.error("restorePurchases failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        #endif
    }

    /// 恢复购买（协议兼容方法）
    func restore() async throws {
        await restorePurchases()
    }

    #if !OPENSOURCE_UNLOCKED
    /// 按 ID 获取商品（供 PaywallView 按类型展示）
    func product(for id: String) -> Product? {
        return products.first { $0.id == id }
    }
    #endif

    /// Pro 商品 ID 列表（供 PaywallView 遍历）
    var productIDs: [String] {
        ProductID.all
    }

    // MARK: - Private

    #if !OPENSOURCE_UNLOCKED

    /// 检查当前已有的活跃权益
    private func checkCurrentEntitlements() async {
        var entitlements: Set<String> = []
        var lifetime = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                entitlements.insert(transaction.productID)
                if transaction.productID == ProductID.lifetime {
                    lifetime = true
                }
            }
        }
        activeEntitlements = entitlements
        hasLifetime = lifetime
    }

    /// 刷新权益并记录日志（供 purchase/restore 调用）
    private func refreshEntitlements() async {
        await checkCurrentEntitlements()
        AppLog.purchase.info("entitlements refreshed: pro=\(isPro) lifetime=\(hasLifetime)")
    }

    /// 持续监听 StoreKit 交易更新（退款、退款争议、跨设备同步等）
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                await MainActor.run {
                    guard let store = self else { return }
                    do {
                        let transaction = try store.checkVerified(result)
                        Task {
                            await transaction.finish()
                            await store.checkCurrentEntitlements()
                        }
                    } catch {
                        store.errorMessage = "交易验证失败：\(error.localizedDescription)"
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
