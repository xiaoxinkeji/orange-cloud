package jiamin.chen.orangecloud.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

// MARK: - WAF 自定义规则（Rulesets，phase = http_request_firewall_custom）

@Serializable
data class WafRuleset(
    val id: String,
    val name: String? = null,
    val phase: String? = null,
    val rules: List<WafRule>? = null,
)

@Serializable
data class WafRule(
    val id: String,
    val action: String? = null,          // block | challenge | managed_challenge | js_challenge | log | skip
    val expression: String? = null,
    val description: String? = null,
    val enabled: Boolean? = null,
    @SerialName("last_updated") val lastUpdated: String? = null,
)

/** PATCH 规则只更新 enabled。 */
@Serializable
data class WafRuleToggle(val enabled: Boolean)

/** 新建规则（POST rules / PUT entrypoint 共用），对齐 iOS WAFRuleCreate。 */
@Serializable
data class WafRuleCreate(
    val action: String,
    val expression: String,
    val description: String? = null,
    val enabled: Boolean,
)

/** PUT entrypoint 创建规则集（Zone 首条自定义规则时）。 */
@Serializable
data class WafEntrypointUpdate(val rules: List<WafRuleCreate>)

// MARK: - Cloudflare Tunnel（cfd_tunnel）

@Serializable
data class Tunnel(
    val id: String,
    val name: String,
    val status: String? = null,          // inactive | degraded | healthy | down
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("conns_active_at") val connsActiveAt: String? = null,
    @SerialName("tun_type") val tunType: String? = null,
    @SerialName("remote_config") val remoteConfig: Boolean? = null,
    val connections: List<TunnelConnection>? = null,
) {
    val activeConnections: Int get() = connections?.size ?: 0
}

@Serializable
data class TunnelConnection(
    val id: String? = null,
    @SerialName("colo_name") val coloName: String? = null,
    @SerialName("origin_ip") val originIp: String? = null,
    @SerialName("opened_at") val openedAt: String? = null,
    @SerialName("client_version") val clientVersion: String? = null,
)

/**
 * 新建隧道（POST /accounts/{id}/cfd_tunnel）。固定远程托管（config_src=cloudflare），
 * 只有远程托管隧道的 ingress 配置能经 API 管理。
 */
@Serializable
data class CreateTunnelRequest(
    val name: String,
    @SerialName("config_src") val configSrc: String = "cloudflare",
)

// MARK: - 隧道配置（公共主机名 / ingress，仅远程托管）

/** GET/PUT /configurations 的 result 外壳。 */
@Serializable
data class TunnelConfigResult(
    @SerialName("tunnel_id") val tunnelId: String? = null,
    val config: TunnelConfig? = null,
)

/**
 * 隧道配置。整组 PUT；未建模的高级字段（originRequest）用 JsonElement 原样保留，避免回写丢失。
 */
@Serializable
data class TunnelConfig(
    val ingress: List<IngressRule>? = null,
    @SerialName("warp-routing") val warpRouting: JsonElement? = null,
    val originRequest: JsonElement? = null,
)

/** 单条 ingress 规则。catch-all（末尾兜底）只有 service、无 hostname。 */
@Serializable
data class IngressRule(
    val hostname: String? = null,
    val service: String,
    val path: String? = null,
    val originRequest: JsonElement? = null,
) {
    /** 是否为兜底规则（无 hostname，或 service 是 http_status 形态）。UI 列表里隐藏它。 */
    val isCatchAll: Boolean
        get() = hostname.isNullOrEmpty() || service.startsWith("http_status:")

    /** 从 service 字符串识别协议种类（用于编辑表单回填）。 */
    val serviceKind: IngressServiceKind
        get() = IngressServiceKind.entries.firstOrNull { it.scheme.isNotEmpty() && service.startsWith(it.scheme) }
            ?: IngressServiceKind.OTHER

    /** 去掉协议前缀后的目标（host:port），OTHER 时为整串。 */
    val serviceTarget: String
        get() = serviceKind.let { if (it == IngressServiceKind.OTHER) service else service.removePrefix(it.scheme) }

    companion object {
        /** catch-all 兜底规则：无 hostname，把其余流量返回 404。 */
        val catchAll = IngressRule(service = "http_status:404")
    }
}

/** 公共主机名表单支持的服务协议。 */
enum class IngressServiceKind(val scheme: String, val label: String) {
    HTTP("http://", "HTTP"),
    HTTPS("https://", "HTTPS"),
    TCP("tcp://", "TCP"),
    SSH("ssh://", "SSH"),
    RDP("rdp://", "RDP"),
    OTHER("", "");

    /** 该协议的默认目标占位。 */
    val targetPlaceholder: String
        get() = when (this) {
            HTTP, HTTPS -> "localhost:8000"
            TCP -> "localhost:5432"
            SSH -> "localhost:22"
            RDP -> "localhost:3389"
            OTHER -> "unix:/path/to.sock"
        }
}

/** PUT /configurations 请求体：{ "config": { … } }。 */
@Serializable
data class TunnelConfigUpdate(val config: TunnelConfig)
