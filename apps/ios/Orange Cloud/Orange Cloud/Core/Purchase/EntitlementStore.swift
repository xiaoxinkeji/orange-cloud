//
//  EntitlementStore.swift
//  Orange Cloud
//
//  StoreKit 2 内购管理。开源构建（OPENSOURCE_UNLOCKED）下 isPro 恒为 true，
// 所有功能免费用，StoreKit 方法变为空操作以保持编译兼容。
//

import Foundation
import StoreKit

// MARK: - Protocol

protocol EntitlementProviding: Observable {
    var isPro: Bool { get }
    func start()
    func purchase() async throws
    func restore() async throws
}

// MARK: - Private

private final class _TaskHolder: @unchecked Sendable {
    var task: Task<Void, Never>?
    init() {}
    deinit { task?.cancel() }
}

// MARK: - EntitlementStore

@Observable
@MainActor
final class EntitlementStore: EntitlementProviding {

    static let shared = EntitlementStore()

    nonisolated enum ProductID {
        static let monthly  = "jiamin.chen.orange_cloud.pro.monthly"
        static let yearly   = "jiamin.chen.orange_cloud.pro.yearly"
        static let lifetime = "jiamin.chen.orange_cloud.pro.lifetime"
        static let all = [yearly, monthly, lifetime]
    }

    // MARK: - Observable State

    var isPro: Bool {
        #if OPENSOURCE_UNLOCKED
        return true
        #else
        return !activeEntitlements.isEmpty
        #endif
    }

    var products: [Product] = []

    var isLoadingProducts: Bool = false

    var purchasingProductID: String? = nil

    var errorMessage: String? = nil

    // MARK: - Private State

    private var activeEntitlements: Set<String> = []

    private var hasLifetime: Bool = false

    private let _taskHolder = _TaskHolder()

    // MARK: - Lifecycle

    private init() {}

    // MARK: - Public API

    func start() {
        #if OPENSOURCE_UNLOCKED
        #else
        _taskHolder.task = listenForTransactions()
        Task {
            await loadProducts()
            await checkCurrentEntitlements()
        }
        #endif
    }

    func loadProducts() async {
        #if OPENSOURCE_UNLOCKED
        #else
        guard products.isEmpty, !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: ProductID.all)
            products = ProductID.all.compactMap { id in loaded.first { $0.id == id } }
            if products.isEmpty {
                AppLog.purchase.error("Product.products(for:) returned empty for: \(ProductID.all.joined(separator: ", "))")
                errorMessage = String(localized: "无法加载商品信息，请稍后再试。")
            } else {
                AppLog.purchase.info("Loaded \(self.products.count) products")
            }
        } catch {
            AppLog.purchase.error("Product.products(for:) failed: \(String(describing: error))")
            errorMessage = String(localized: "无法加载商品信息，请稍后再试。")
        }
        #endif
    }

    func purchase() async throws {
        #if OPENSOURCE_UNLOCKED
        #else
        guard let product = products.first ?? pickPreferredProduct() else {
            let error = EntitlementError.noProductsAvailable
            errorMessage = error.localizedDescription
            throw error
        }
        try await purchase(product: product)
        #endif
    }

    func purchase(product: Product) async throws {
        #if OPENSOURCE_UNLOCKED
        #else
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
        @unknown default:
            break
        }
        #endif
    }

    func restorePurchases() async {
        #if OPENSOURCE_UNLOCKED
        #else
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

    func restore() async throws {
        await restorePurchases()
    }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    var productIDs: [String] {
        ProductID.all
    }

    // MARK: - Private

    private func checkCurrentEntitlements() async {
        #if OPENSOURCE_UNLOCKED
        #else
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
        #endif
    }

    private func refreshEntitlements() async {
        await checkCurrentEntitlements()
        AppLog.purchase.info("entitlements refreshed: pro=\(isPro) lifetime=\(hasLifetime)")
    }

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
                        store.errorMessage = "Transaction verification failed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    private func pickPreferredProduct() -> Product? {
        let preferred = [ProductID.lifetime, ProductID.yearly, ProductID.monthly]
        for id in preferred {
            if let p = products.first(where: { $0.id == id }) { return p }
        }
        return products.first
    }
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
