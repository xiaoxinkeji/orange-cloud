//
//  TokenEntryView.swift
//  Orange Cloud
//
//  API Token 添加入口：粘贴 Bearer Token → 验证 → 保存为新身份。
//  从 SettingsView 的「使用 API Token」按钮打开。
//

import SwiftUI

struct TokenEntryView: View {

    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var tokenText = ""
    @State private var label = ""
    @State private var isVerifying = false
    @State private var verifyError: String?
    @State private var verifiedEmail: String?

    private static let apiTokenURL = URL(string: "https://dash.cloudflare.com/profile/api-tokens")!

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        dismiss()
                        UIApplication.shared.open(Self.apiTokenURL)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "safari")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("在 App 内创建 Token")
                                Text("跳转 Safari 打开 Cloudflare 控制台，登录后可生成 Token。")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("获取 Token")
                } footer: {
                    Text("非必须。已有 Token 可直接在下方的输入框中粘贴。")
                }

                Section {
                    SecureField("粘贴 API Token", text: $tokenText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.callout.monospaced())
                        .onChange(of: tokenText) { _, _ in
                            verifiedEmail = nil
                            verifyError = nil
                        }
                } header: {
                    Text("Bearer Token")
                } footer: {
                    Text("在 Cloudflare Dashboard → 我的个人资料 → API 令牌 中创建。")
                }

                Section {
                    TextField("例如 生产环境", text: $label)
                } header: {
                    Text("标签（可选）")
                }

                Section {
                    Button {
                        Task { await verifyAndAdd() }
                    } label: {
                        HStack {
                            Spacer()
                            if isVerifying {
                                ProgressView()
                            } else {
                                Text("验证并添加")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(tokenText.trimmingCharacters(in: .whitespaces).isEmpty || isVerifying)
                }

                if let email = verifiedEmail {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Text("Token 有效（\(email)）")
                                .font(.callout)
                        }
                    }
                }

                if let error = verifyError {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "xmark.octagon.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.callout)
                        }
                    }
                }
            }
            .navigationTitle("API Token")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @MainActor
    private func verifyAndAdd() async {
        let token = tokenText.trimmingCharacters(in: .whitespaces)
        guard !token.isEmpty else { return }
        isVerifying = true
        verifyError = nil
        verifiedEmail = nil

        guard let email = await auth.verifyToken(token) else {
            verifyError = String(localized: "Token 无效或已失效，请检查后重试。")
            isVerifying = false
            return
        }
        verifiedEmail = email

        let displayLabel = label.trimmingCharacters(in: .whitespaces).isEmpty
            ? email
            : label.trimmingCharacters(in: .whitespaces)

        auth.addAPIToken(token, label: displayLabel)
        isVerifying = false
        dismiss()
    }
}
