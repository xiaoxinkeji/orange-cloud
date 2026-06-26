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

    var body: some View {
        ContentUnavailableView {
            Label("\(featureName) 未授权", systemImage: "lock.shield")
        } description: {
            Text(message ?? "当前授权未包含「\(featureName)」的访问权限（\(requiredScope)）。\n请在设置中退出登录后重新授权以启用此功能。")
        }
    }
}

#Preview {
    PermissionDeniedView(featureName: "Workers", requiredScope: "workers-scripts.read")
}
