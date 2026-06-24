//
//  WorkerEditorView.swift
//  Orange Cloud
//
//  Workers 代码编辑器：TextEditor + 部署按钮。
//

import SwiftUI

struct WorkerEditorView: View {

    let accountId: String
    let scriptName: String
    let session: SessionStore

    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var originalContent = ""
    @State private var isLoading = true
    @State private var isDeploying = false
    @State private var error: String?
    @State private var successMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("加载脚本...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                editorContent
            }
        }
        .navigationTitle(scriptName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                deployButton
            }
        }
        .alert("错误", isPresented: .init(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(error ?? "")
        }
        .task {
            await loadScript()
        }
    }

    // MARK: - 编辑器

    private var editorContent: some View {
        VStack(spacing: 0) {
            if let successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(successMessage)
                        .font(.subheadline)
                    Spacer()
                    Button {
                        self.successMessage = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
            }

            TextEditor(text: $content)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background { SkyBackground() }
    }

    // MARK: - 部署按钮

    @ViewBuilder
    private var deployButton: some View {
        if isDeploying {
            ProgressView()
        } else {
            let hasChanges = content != originalContent
            Button {
                Task { await deploy() }
            } label: {
                Text("部署")
                    .fontWeight(.semibold)
            }
            .disabled(!hasChanges || isDeploying)
        }
    }

    // MARK: - 操作

    private func loadScript() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let script = try await session.workerService.getScriptContent(
                accountId: accountId,
                scriptName: scriptName
            )
            content = script
            originalContent = script
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func deploy() async {
        guard content != originalContent else { return }
        isDeploying = true
        defer { isDeploying = false }
        do {
            _ = try await session.workerService.updateScript(
                accountId: accountId,
                scriptName: scriptName,
                content: content,
                metadata: WorkerScriptMetadata()
            )
            originalContent = content
            successMessage = String(localized: "已部署到 Cloudflare 全球网络")
        } catch {
            self.error = error.localizedDescription
        }
    }
}
