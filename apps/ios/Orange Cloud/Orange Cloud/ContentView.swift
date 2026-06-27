//
//  ContentView.swift
//  Orange Cloud
//
//  根视图：按登录态路由到欢迎页或主界面。
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @Environment(AuthManager.self) private var auth

    var body: some View {
        Group {
            if auth.isLoggedIn {
                // 按身份重建会话子树：切换/新增登录身份时 SessionStore（含 token 客户端）全新创建
                SessionRootView(auth: auth)
                    .id(auth.currentSessionId)
            } else {
                LoginView()
            }
        }
        .animation(.smooth, value: auth.isLoggedIn)
    }
}

/// 登录后才存在的子树：持有本次会话的 SessionStore（API Client + Services）
private struct SessionRootView: View {

    @State private var session: SessionStore

    init(auth: AuthManager) {
        _session = State(initialValue: SessionStore(authManager: auth))
    }

    var body: some View {
        MainTabView()
            .environment(session)
            .whatsNewSheet()
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
        .modelContainer(for: [CachedZone.self, CachedDNSRecord.self], inMemory: true)
}
