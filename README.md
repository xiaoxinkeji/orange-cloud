<div align="center">

<img src="apps/web/public/icons/icon-512.png" width="120" alt="Orange Cloud" />

# Orange Cloud

**A native iOS client for Cloudflare — sign in with OAuth, no API token pasting.**

[Website](https://orange-cloud.chatiro.app) · [Privacy](https://orange-cloud.chatiro.app/privacy) · [Terms](https://orange-cloud.chatiro.app/terms) · [Releases](https://github.com/xiaoxinkeji/orange-cloud/releases)

[English](#english) | [中文](#中文)

</div>

---

## English

Orange Cloud is a third-party Cloudflare management app for iPhone and iPad, built entirely with Swift and SwiftUI for iOS 26+. Unlike other clients, it authenticates through Cloudflare's official[...]

<div align="center">
<img src="apps/web/public/shots/en/01_dashboard.jpg" width="230" alt="Dashboard" />
<img src="apps/web/public/shots/en/02_analytics.jpg" width="230" alt="Analytics" />
<img src="apps/web/public/shots/en/06_workers_tail.jpg" width="230" alt="Workers live tail" />
</div>

### Features

- **OAuth 2.0 + PKCE sign-in** with per-scope permission selection; tokens are stored in the Keychain only, and multiple Cloudflare accounts can stay signed in side by side
- **Domains & DNS**: zone list, full DNS record CRUD, zone settings
- **Analytics**: zone traffic via the GraphQL Analytics API, rendered with Swift Charts
- **Workers**: script list and details, plus real-time log streaming (`wrangler tail`-style WebSocket trace) with a Live Activity on the Lock Screen and Dynamic Island
- **Storage**: R2 bucket and object browsing, D1 SQL console, KV key-value management
- **Security & network**: WAF custom rules (view / toggle) and Cloudflare Tunnel status
- **Deep system integration**: Home Screen widgets, Control Center controls, Siri / App Intents, Spotlight indexing, background token refresh, and an iPad split-view layout
- **Localized** in English, 简体中文, 繁體中文（台灣）, 繁體中文（香港）, and 日本語

### Open source & self-signed builds

This fork removes the Pro/membership mechanism entirely — all features are unlocked by default for self-signed builds. The CI pipeline automatically builds an unsigned IPA on every versioned tag push (`v*`), uploaded as a GitHub Release artifact. Just sign it with AltStore, SideStore, or your own developer certificate and install.

The repository is licensed under **AGPL-3.0 + Commons Clause**.

### Repository layout

```
orange-cloud/
├── apps/
│   ├── ios/        # The iOS app (Swift / SwiftUI, Xcode project)
│   └── web/        # Landing page + OAuth callback relay (Next.js on Cloudflare Workers)
├── package.json    # pnpm workspaces root
└── turbo.json
```

### Building from source

1. **Xcode 26+** (iOS 26 SDK). Open `apps/ios/Orange Cloud/Orange Cloud.xcodeproj`.
2. Create your own **Cloudflare OAuth client** and deploy your own callback relay (see [`apps/web/`](apps/web/README.md)) — the official client ID and `orange-cloud.chatiro.app` relay are not available for third-party builds.
3. Change the Bundle ID, App Group, and signing team to your own.
4. Build and run — all features are unlocked by default.

For automated CI builds, push a version tag (e.g. `v1.0.0`) and the workflow will produce an unsigned IPA.

Full details, including the contribution workflow and CLA, are in [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 中文

Orange Cloud 是一款 iPhone / iPad 原生的 Cloudflare 第三方管理客户端，使用 Swift + SwiftUI 构建，最低支持 iOS 26。与其他客户端不同，它走 Cloudflare 官方 **OAu[...]

<div align="center">
<img src="apps/web/public/shots/zh-Hans/01_dashboard.jpg" width="230" alt="概览" />
<img src="apps/web/public/shots/zh-Hans/02_analytics.jpg" width="230" alt="流量分析" />
<img src="apps/web/public/shots/zh-Hans/06_workers_tail.jpg" width="230" alt="Workers 实时日志" />
</div>

### 功能

- **OAuth 2.0 + PKCE 登录**，按 scope 勾选授权；Token 只存 Keychain，支持多个 Cloudflare 账号并存切换
- **域名与 DNS**：域名列表、DNS 记录增删改查、域名设置
- **流量分析**：GraphQL Analytics API + Swift Charts 图表
- **Workers**：脚本列表与详情、实时日志流（WebSocket trace，类似 `wrangler tail`），配合锁屏 / 灵动岛 Live Activity
- **存储**：R2 存储桶与对象浏览、D1 SQL 查询控制台、KV 键值管理
- **安全与网络**：WAF 自定义规则（查看 / 启停）、Cloudflare 隧道状态
- **系统深度集成**：主屏小组件、控制中心控件、Siri / App Intents、Spotlight 索引、后台 Token 静默刷新、iPad 双栏布局
- **五语言本地化**：简体中文、繁體中文（台灣）、繁體中文（香港）、English、日本語

### 开源与自签构建

此 Fork 移除了 Pro/会员机制，所有功能默认解锁。CI 流水线会在每次推送版本标签（`v*`）时自动编译未签名 IPA，发布为 GitHub Release 附件，使用 AltStore、SideStore 或自有开发者证书签名即可安装。

本仓库采用 **AGPL-3.0 + Commons Clause** 许可。

### 自行编译

1. **Xcode 26+**（iOS 26 SDK），打开 `apps/ios/Orange Cloud/Orange Cloud.xcodeproj`。
2. 自建 **Cloudflare OAuth Client** 并部署自己的回调中转（见 [`apps/web/`](apps/web/README.md)）——官方 Client ID 与 `orange-cloud.chatiro.app` 中转不向第三方构建开放。
3. Bundle ID / App Group / 签名团队改为你自己的。
4. 构建运行即可，所有功能默认解锁。

推送版本标签（如 `v1.0.0`）即可触发 CI 自动编译未签名 IPA。

贡献流程与 CLA 详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

<div align="center">

© 2026 [chen2he](https://github.com/chen2he) · AGPL-3.0 + Commons Clause

</div>
