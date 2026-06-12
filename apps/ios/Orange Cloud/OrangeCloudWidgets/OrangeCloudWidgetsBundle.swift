//
//  OrangeCloudWidgetsBundle.swift
//  OrangeCloudWidgets
//

import WidgetKit
import SwiftUI

@main
struct OrangeCloudWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ZoneStatWidget()
        ZoneChartWidget()
        UsageWidget()
        ZoneStatusWidget()
        OrangeCloudControlWidget()
        TailLiveActivityWidget()
    }
}
