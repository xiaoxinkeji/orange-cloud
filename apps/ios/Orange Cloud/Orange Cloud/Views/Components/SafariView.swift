//
//  SafariView.swift
//  Orange Cloud
//
//  内嵌 Safari 浏览器（SFSafariViewController），用于在 App 内打开网页，
//  不跳转系统 Safari。API Token 创建等场景使用。
//

import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
