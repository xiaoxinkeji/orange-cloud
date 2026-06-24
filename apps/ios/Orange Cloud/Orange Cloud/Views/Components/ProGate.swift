//
//  ProGate.swift
//  Orange Cloud
//
//  已退化为 PermissionGatedNavigationLink 的透明包装。
//  无付费墙机制，所有功能直接可用。
//

import SwiftUI

struct ProGatedNavigationLink<Destination: View>: View {

    let label:         String
    let systemImage:   String
    let requiredScope: String
    var tint: Color = .ocOrange
    var showsChevron: Bool = false
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        PermissionGatedNavigationLink(
            label: label,
            systemImage: systemImage,
            requiredScope: requiredScope,
            tint: tint,
            showsChevron: showsChevron,
            destination: destination
        )
    }
}
