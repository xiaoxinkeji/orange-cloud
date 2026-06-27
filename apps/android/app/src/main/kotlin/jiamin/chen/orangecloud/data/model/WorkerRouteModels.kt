package jiamin.chen.orangecloud.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Worker 的域名/路由模型（对应 iOS WorkerRouteModels.swift）。
 * GET/POST /accounts/{a}/workers/scripts/{n}/subdomain   workers.dev 子域开关
 * GET/PUT/DELETE /accounts/{a}/workers/domains            自定义域（按 service 过滤到本脚本）
 * GET/POST/DELETE /zones/{z}/workers/routes               Zone 路由（pattern → script）
 */

// MARK: - workers.dev 子域

/** 脚本的 workers.dev 子域路由状态。 */
@Serializable
data class WorkerSubdomain(
    val enabled: Boolean = false,
    @SerialName("previews_enabled") val previewsEnabled: Boolean? = null,
)

/** 切换 workers.dev 子域（POST body）。 */
@Serializable
data class WorkerSubdomainInput(val enabled: Boolean)

// MARK: - 自定义域

/** Worker 自定义域（账号级，service = 脚本名）。 */
@Serializable
data class WorkerCustomDomain(
    val id: String = "",
    val hostname: String = "",
    val service: String? = null,
    @SerialName("zone_id") val zoneId: String? = null,
    @SerialName("zone_name") val zoneName: String? = null,
    val environment: String? = null,
)

/** 挂载自定义域（PUT .../domains）。 */
@Serializable
data class WorkerCustomDomainInput(
    val hostname: String,
    val service: String,
    @SerialName("zone_id") val zoneId: String,
    val environment: String = "production",
)

// MARK: - Zone 路由

/** Zone 级 Worker 路由（GET /zones/{z}/workers/routes）。 */
@Serializable
data class WorkerRoute(
    val id: String = "",
    val pattern: String = "",
    val script: String? = null,
)

/** 新建路由（POST，body {pattern, script}）。 */
@Serializable
data class WorkerRouteInput(
    val pattern: String,
    val script: String,
)

/** 带 zone 上下文的路由（路由本身按 zone 查询，聚合展示/删除时需带 zone）。运行期结构，非 API 模型。 */
data class ScopedWorkerRoute(
    val zoneId: String,
    val zoneName: String,
    val route: WorkerRoute,
)
