//
//  Theme.swift
//  Orange Cloud
//
//  设计系统色板（orange-cloud/project/_ds/tokens/colors.css）。
//  品牌主色是 Cloudflare 橙 #F48120，不是系统橙。
//

import SwiftUI

nonisolated extension Color {

    /// Cloudflare 品牌橙 #F48120 — CTA、选中态、高亮
    static let ocOrange = Color(red: 0xF4 / 255, green: 0x81 / 255, blue: 0x20 / 255)

    /// 按压态 #D86F12
    static let ocOrangePressed = Color(red: 0xD8 / 255, green: 0x6F / 255, blue: 0x12 / 255)

    /// Enterprise 金 #C99A1E
    static let ocGold = Color(red: 0xC9 / 255, green: 0x9A / 255, blue: 0x1E / 255)
}

/// 域名字母头像的哈希色板（与设计稿 AV_PALETTE 一致）
nonisolated enum AvatarPalette {

    static let colors: [Color] = [
        Color(red: 0xE8 / 255, green: 0x74 / 255, blue: 0x3B / 255),
        Color(red: 0x3D / 255, green: 0x86 / 255, blue: 0xE0 / 255),
        Color(red: 0x1F / 255, green: 0x9D / 255, blue: 0x5B / 255),
        Color(red: 0x9B / 255, green: 0x59 / 255, blue: 0xC9 / 255),
        Color(red: 0xE0 / 255, green: 0x50 / 255, blue: 0x8C / 255),
        Color(red: 0xC9 / 255, green: 0x9A / 255, blue: 0x1E / 255),
        Color(red: 0x2B / 255, green: 0xAF / 255, blue: 0xA6 / 255),
        Color(red: 0x5B / 255, green: 0x6C / 255, blue: 0xE0 / 255),
        Color(red: 0xD8 / 255, green: 0x5C / 255, blue: 0x5C / 255),
        Color(red: 0x4F / 255, green: 0x7C / 255, blue: 0x9C / 255),
    ]

    /// 与设计稿一致的字符串哈希：h = h * 31 + char
    static func color(for text: String) -> Color {
        var hash: UInt32 = 0
        for unit in text.unicodeScalars {
            hash = hash &* 31 &+ UInt32(unit.value)
        }
        return colors[Int(hash % UInt32(colors.count))]
    }
}
