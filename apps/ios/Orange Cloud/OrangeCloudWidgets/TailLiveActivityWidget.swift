//
//  TailLiveActivityWidget.swift
//  OrangeCloudWidgets
//
//  Workers 实时日志的 Live Activity：锁屏卡片 + Dynamic Island。
//

import WidgetKit
import SwiftUI
import ActivityKit

struct TailLiveActivityWidget: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TailActivityAttributes.self) { context in
            // 锁屏 / 横幅
            LockScreenTailView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.6))
                .activitySystemActionForegroundColor(Color.ocOrange)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(Color.ocOrange)
                        Text(context.attributes.scriptName)
                            .font(.caption.bold())
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.eventCount) 事件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.lastLine.isEmpty ? String(localized: "等待事件…") : context.state.lastLine)
                        .font(.caption2.monospaced())
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Color.ocOrange)
            } compactTrailing: {
                Text("\(context.state.eventCount)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(context.state.isConnected ? .green : .red)
            } minimal: {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Color.ocOrange)
            }
        }
    }
}

private struct LockScreenTailView: View {

    let context: ActivityViewContext<TailActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(context.attributes.scriptName, systemImage: "bolt.fill")
                    .font(.callout.bold())
                    .foregroundStyle(Color.ocOrange)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(context.state.isConnected ? .green : .red)
                        .frame(width: 6, height: 6)
                    Text("\(context.state.eventCount) 事件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(context.state.lastLine.isEmpty ? String(localized: "正在监听实时日志…") : context.state.lastLine)
                .font(.caption.monospaced())
                .lineLimit(2)
                .foregroundStyle(.primary)
        }
        .padding()
    }
}
