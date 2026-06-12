//
//  WorkerTailViewModel.swift
//  Orange Cloud
//
//  Workers 实时日志编排：创建 tail session → 连接 WebSocket → 消费事件流。
//  断线/过期自动重建一次，再失败交给用户手动重连；退出时销毁 tail。
//

import Foundation
import Observation
import ActivityKit

@Observable
@MainActor
final class WorkerTailViewModel {

    enum ConnectionState: Equatable {
        case idle
        case connecting
        case connected
        case disconnected(reason: String?)
    }

    nonisolated struct LogLine: Identifiable, Sendable {
        let id: UUID
        let timestamp: Date
        let level: String      // "event" | "log" | "info" | "warn" | "error" | "exception"
        let text: String
    }

    private(set) var lines: [LogLine] = []
    private(set) var state: ConnectionState = .idle
    var isPaused = false       // 暂停 = 丢弃新事件，连接保持

    private let service: WorkerTailService
    private let accountId: String
    private let scriptName: String

    private var socket: TailSocket?
    private var streamTask: Task<Void, Never>?
    private var tailId: String?
    private var didAutoReconnect = false
    private var userStopped = false

    // Live Activity（Dynamic Island + 锁屏）
    private var activity: Activity<TailActivityAttributes>?
    private var eventCount = 0
    private var lastActivityUpdate = Date.distantPast

    private static let maxLines = 1000

    init(service: WorkerTailService, accountId: String, scriptName: String) {
        self.service = service
        self.accountId = accountId
        self.scriptName = scriptName
    }

    // MARK: - 生命周期

    func start() async {
        await teardown()
        userStopped = false
        didAutoReconnect = false
        await connect()
    }

    func stop() async {
        userStopped = true
        await teardown()
        endActivity()
        state = .idle
    }

    func clear() {
        lines.removeAll()
    }

    private func connect() async {
        state = .connecting
        do {
            let session = try await service.createTail(accountId: accountId, scriptName: scriptName)
            tailId = session.id
            let socket = try service.makeSocket(for: session)
            self.socket = socket
            state = .connected
            startActivityIfNeeded()

            streamTask = Task {
                do {
                    for try await item in await socket.events() {
                        handle(item)
                    }
                    streamEnded(error: nil)
                } catch {
                    streamEnded(error: error)
                }
            }
        } catch {
            state = .disconnected(reason: error.localizedDescription)
        }
    }

    private func teardown() async {
        streamTask?.cancel()
        streamTask = nil
        if let socket {
            await socket.close()
        }
        socket = nil
        if let tailId {
            let id = tailId
            self.tailId = nil
            // 尽力销毁，失败不阻塞
            try? await service.deleteTail(accountId: accountId, scriptName: scriptName, tailId: id)
        }
    }

    /// 流结束：用户主动停止则忽略；否则自动重建一次，再失败转为断开态
    private func streamEnded(error: Error?) {
        guard !userStopped else { return }
        if !didAutoReconnect {
            didAutoReconnect = true
            Task {
                await teardown()
                await connect()
            }
        } else {
            state = .disconnected(reason: error?.localizedDescription ?? String(localized: "连接已断开"))
            updateActivity(force: true)
        }
    }

    // MARK: - 事件 → 日志行

    private func handle(_ item: TailTraceItem) {
        guard !isPaused else { return }

        var newLines: [LogLine] = []
        let eventDate = item.eventTimestamp.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) } ?? Date()

        // 触发事件概要行
        if let request = item.event?.request {
            let method = request.method ?? "GET"
            let url = request.url ?? ""
            let outcome = item.outcome ?? "?"
            newLines.append(LogLine(id: UUID(), timestamp: eventDate, level: "event",
                                    text: "\(method) \(url) → \(outcome)"))
        } else if let cron = item.event?.cron {
            newLines.append(LogLine(id: UUID(), timestamp: eventDate, level: "event",
                                    text: "cron \(cron) → \(item.outcome ?? "?")"))
        }

        // console.* 输出
        for log in item.logs ?? [] {
            let date = log.timestamp.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) } ?? eventDate
            let text = (log.message ?? []).map(\.displayText).joined(separator: " ")
            newLines.append(LogLine(id: UUID(), timestamp: date, level: log.level, text: text))
        }

        // 异常
        for exception in item.exceptions ?? [] {
            let date = exception.timestamp.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) } ?? eventDate
            let text = [exception.name, exception.message].compactMap(\.self).joined(separator: ": ")
            newLines.append(LogLine(id: UUID(), timestamp: date, level: "exception", text: text))
        }

        lines.append(contentsOf: newLines)
        if lines.count > Self.maxLines {
            lines.removeFirst(lines.count - Self.maxLines)
        }

        eventCount += 1
        updateActivity()
    }

    // MARK: - Live Activity

    private func startActivityIfNeeded() {
        guard activity == nil,
              ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        eventCount = 0
        let content = ActivityContent(
            state: TailActivityAttributes.ContentState(eventCount: 0, lastLine: "", isConnected: true),
            staleDate: nil
        )
        activity = try? Activity.request(
            attributes: TailActivityAttributes(scriptName: scriptName),
            content: content
        )
    }

    /// 节流更新：默认 1 秒一次，连接状态变化时强制
    private func updateActivity(force: Bool = false) {
        guard let activity else { return }
        guard force || Date().timeIntervalSince(lastActivityUpdate) > 1 else { return }
        lastActivityUpdate = Date()
        let content = ActivityContent(
            state: TailActivityAttributes.ContentState(
                eventCount: eventCount,
                lastLine: lines.last?.text ?? "",
                isConnected: state == .connected
            ),
            staleDate: nil
        )
        Task { await activity.update(content) }
    }

    private func endActivity() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}
