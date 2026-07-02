//
//  WorkerEditorView.swift
//  Orange Cloud
//
//  Worker 在线编辑器：读取源码、编辑、保存。仅支持单模块/Service Worker。
//  多模块（bundle产物）只读展示，不可编辑。
//

import SwiftUI

struct WorkerEditorView: View {

    let accountId: String
    let scriptName: String
    let session: SessionStore

    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var content: WorkerContent?
    @State private var settings: WorkerSettings?
    @State private var code: String = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var error: String?
    @State private var showSaveConfirm = false
    @State private var saveError: String?

    private var canWrite: Bool { auth.hasScope("workers-scripts.write") }
    private var isEditable: Bool { content?.isEditable ?? false }
    private var moduleName: String { content?.mainModule?.name ?? "worker.js" }

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("加载脚本代码…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if !isEditable {
                ContentUnavailableView {
                    Label("代码不可编辑", systemImage: "lock")
                } description: {
                    Text("该脚本包含多个模块（绑定产物），手机端暂不支持编辑。请在 Cloudflare Dashboard 或 Wrangler 中修改。")
                }
            } else {
                codeEditor
            }
        }
        .navigationTitle(scriptName)
        .navigationBarTitleDisplayMode(.inline)
        .background(SkyBackground())
        .task {
            await loadCode()
        }
        .alert("保存失败", isPresented: .init(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
    }

    // MARK: - 编辑器

    private var codeEditor: some View {
        VStack(spacing: 0) {
            // 编辑器工具栏
            HStack {
                Text(moduleName)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Spacer()
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Button("保存") {
                    showSaveConfirm = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.ocOrange)
                .disabled(!canWrite || isSaving)
                .fontWeight(.bold)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            #if os(iOS)
            .background(.regularMaterial)
            #endif

            // 代码编辑区
            #if os(iOS)
            TextEditor(text: $code)
                .font(.system(.caption, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground).opacity(0.3))
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .padding(.horizontal, 4)
            #else
            TextEditor(text: $code)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 4)
            #endif
        }
        .confirmationDialog("保存代码？", isPresented: $showSaveConfirm, titleVisibility: .visible) {
            Button("保存") {
                Task { await saveCode() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将更新 Worker「\(scriptName)」的代码，现有绑定和触发器将保持不变。")
        }
    }

    // MARK: - 加载代码

    private func loadCode() async {
        isLoading = true
        error = nil
        do {
            async let c = session.workerService.content(accountId: accountId, scriptName: scriptName)
            async let s = session.workerService.settings(accountId: accountId, scriptName: scriptName)
            let (loadedContent, loadedSettings) = try await (c, s)
            content = loadedContent
            settings = loadedSettings
            if let module = loadedContent.mainModule {
                code = module.body
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - 保存代码

    private func saveCode() async {
        guard canWrite, let content, let settings else { return }
        isSaving = true
        saveError = nil
        do {
            try await session.workerService.uploadScript(
                accountId: accountId,
                scriptName: scriptName,
                content: content,
                newCode: code,
                settings: settings
            )
            isSaving = false
            dismiss()
        } catch {
            saveError = error.localizedDescription
            isSaving = false
        }
    }
}
