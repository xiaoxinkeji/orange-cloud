//
//  PaywallView.swift
//  Orange Cloud
//
//  Pro 付费墙：展示 Pro 功能列表、各商品购买按钮、购买中加载态、已解锁感谢页。
//  自签构建（OPENSOURCE_UNLOCKED）时 isPro 恒为 true，直接展示已解锁状态。
//

import SwiftUI
#if !OPENSOURCE_UNLOCKED
import StoreKit
#endif

struct PaywallView: View {

    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if entitlements.isPro {
                        unlockedView
                    } else {
                        paywallContent
                    }
                }
                .padding(.horizontal, OCLayout.pagePadding)
                .padding(.vertical, 24)
            }
            .background { SkyBackground() }
            .navigationTitle("Orange Cloud Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            #if !OPENSOURCE_UNLOCKED
            .overlay {
                if let id = entitlements.purchasingProductID {
                    purchasingOverlay(productID: id)
                }
            }
            .alert(
                "购买失败",
                isPresented: .constant(entitlements.errorMessage != nil),
                presenting: entitlements.errorMessage
            ) { _ in
                Button("好") { entitlements.errorMessage = nil }
            } message: { msg in
                Text(msg)
            }
            #endif
        }
    }

    // MARK: - 已解锁

    private var unlockedView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.ocOrange, .orange],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: .ocOrange.opacity(0.4), radius: 20)

            Text("Pro 已解锁")
                .font(.title.weight(.bold))

            Text("感谢你的支持！所有 Pro 功能已解锁。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 12)

            featuresList
                .glassIsland()
                .padding(.horizontal, 4)
        }
    }

    // MARK: - 付费墙内容

    #if !OPENSOURCE_UNLOCKED
    private var paywallContent: some View {
        VStack(spacing: 20) {
            heroSection
            featuresSection
            productsSection
            restoreSection
        }
    }
    #else
    private var paywallContent: some View {
        // OPENSOURCE_UNLOCKED 下不会执行到此分支（isPro 恒为 true）
        EmptyView()
    }
    #endif

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.ocOrange, .yellow],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .ocOrange.opacity(0.5), radius: 16)

            Text("解锁完整功能")
                .font(.title2.weight(.bold))

            Text("Orange Cloud Pro 解锁全部高级功能，让你的 Cloudflare 管理体验更强大。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 4)
    }

    // MARK: - 功能列表

    private var featuresSection: some View {
        featuresList
            .glassIsland()
    }

    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow(icon: "person.2.fill",                color: .ocOrange, title: "多账号管理",    desc: "同时管理多个 Cloudflare 账号，快速切换")
            featureRow(icon: "chart.line.uptrend.xyaxis",    color: .blue,     title: "高级分析",      desc: "详细的流量、带宽、请求趋势图表")
            featureRow(icon: "terminal.fill",                color: .indigo,   title: "Worker 实时日志", desc: "实时 Tail 查看 Worker 运行状态")
            featureRow(icon: "shield.lefthalf.filled",       color: .red,      title: "WAF 与防火墙",   desc: "管理 Web 应用防火墙规则集")
            featureRow(icon: "arrow.triangle.2.circlepath",  color: .green,    title: "后台刷新",      desc: "自动检测 Zone 状态变化并推送通知")
            featureRow(icon: "bell.badge.fill",              color: .orange,   title: "智能通知",      desc: "Zone 异常、Worker 错误即时提醒")
        }
        .padding(OCLayout.islandPadding)
    }

    private func featureRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            TintIcon(systemImage: icon, color: color, size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - 商品购买

    #if !OPENSOURCE_UNLOCKED

    private var productsSection: some View {
        VStack(spacing: 12) {
            if entitlements.isLoadingProducts {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("加载商品中...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .glassIsland()
            } else if entitlements.products.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "wifi.exclamationmark")
                        .foregroundStyle(.secondary)
                    Text("无法加载商品，请检查网络连接")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .glassIsland()
            } else {
                ForEach(entitlements.productIDs, id: \.self) { id in
                    if let product = entitlements.product(for: id) {
                        productCard(product: product, id: id)
                    }
                }
            }
        }
    }

    private func productCard(product: Product, id: String) -> some View {
        let isPurchasing = entitlements.purchasingProductID == id

        return Button {
            Task {
                do {
                    try await entitlements.purchase(product: product)
                } catch {
                    // errorMessage 已在 store 内设置
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(productDisplayName(id: id))
                            .font(.subheadline.weight(.semibold))
                        if id == EntitlementStore.ProductID.lifetime {
                            Text("推荐")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.ocOrange, in: Capsule())
                        }
                    }
                    Text(productDescription(id: id))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.ocOrange)

                if isPurchasing {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(OCLayout.islandPadding)
        }
        .buttonStyle(.plain)
        .glassIsland()
        .disabled(isPurchasing || entitlements.purchasingProductID != nil)
    }

    private func purchasingOverlay(productID: String) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                Text("正在处理购买...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .glassIsland()
        }
    }

    #endif

    // MARK: - 恢复

    private var restoreSection: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    do {
                        try await entitlements.restore()
                    } catch {
                        // errorMessage 已在 store 内设置
                    }
                }
            } label: {
                Text("恢复购买")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("购买将记入你的 Apple ID 账户。订阅将在当前周期结束前至少 24 小时自动续订。你可以在 Apple ID 账户设置中管理和取消订阅。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.top, 8)
    }

    // MARK: - 商品名称/描述

    private func productDisplayName(id: String) -> String {
        switch id {
        case EntitlementStore.ProductID.lifetime: return "永久解锁"
        case EntitlementStore.ProductID.yearly:   return "年度订阅"
        case EntitlementStore.ProductID.monthly:  return "月度订阅"
        default:                                  return id
        }
    }

    private func productDescription(id: String) -> String {
        switch id {
        case EntitlementStore.ProductID.lifetime: return "一次购买，永久使用所有 Pro 功能"
        case EntitlementStore.ProductID.yearly:   return "按年付费，更优惠的选择"
        case EntitlementStore.ProductID.monthly:  return "按月付费，随时取消"
        default:                                  return ""
        }
    }
}

#Preview {
    PaywallView()
        .environment(EntitlementStore.shared)
}
