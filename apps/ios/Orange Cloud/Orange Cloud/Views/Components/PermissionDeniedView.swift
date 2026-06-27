//
//  PermissionDeniedView.swift
//  Orange Cloud
//
//  整页锁定态：当前授权不包含某功能所需 scope 时占满内容区展示。
//

import SwiftUI

struct PermissionDeniedView: View {

    let featureName:   String
    let requiredScope: String
    var message:       String?

    @Environment(AuthManager.self) private var auth

    var body: some View {
        ContentUnavailableView {
            Label("\(featureName) 未授权", systemImage: "lock.shield")
        } description: {
            Text(message ?? "当前授权未包含「\(featureName)」的访问权限（\(requiredScope)）。\n请在设置中退出登录后重新授权以启用此功能。")
        } actions: {
            if let sessionId = auth.currentSessionId {
                ReauthorizeButton(sessionId: sessionId, scopes: [requiredScope])
                    .buttonStyle(.borderedProminent)
                    .tint(Color.ocOrangePressed)
                    .fontWeight(.bold)
            }
        }
    }
}

#Preview {
    PermissionDeniedView(featureName: "Workers", requiredScope: "workers-scripts.read")
        .environment(AuthManager())
}
