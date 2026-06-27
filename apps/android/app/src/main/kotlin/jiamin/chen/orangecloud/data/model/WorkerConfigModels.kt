package jiamin.chen.orangecloud.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Workers 脚本管理（变量 / 密钥 / 触发器）相关模型（对应 iOS WorkerConfigModels.swift）。
 * 源码读取端点在 OAuth 登录下被 Cloudflare 拒绝（cf=10405），故客户端不做脚本编辑，仅做配置管理。
 *
 * GET  /accounts/{a}/workers/scripts/{n}/settings    绑定 + 兼容性日期/标志
 * PATCH .../settings (multipart settings part)        改绑定（变量），其余绑定回传 inherit
 * GET/PUT/DELETE .../secrets                           密钥（仅名+类型，无值）
 * GET/PUT .../schedules                                Cron 触发器（整组替换）
 */

// MARK: - 绑定与设置

/**
 * 脚本绑定（KV / D1 / R2 / 密钥 / 变量 等）。读展示与 inherit 回传只需 type/name；变量另读 text。
 * 未建模的新绑定类型不致整页失败（缺字段降级为空串，调用方过滤空名）。
 */
@Serializable
data class WorkerBinding(
    val type: String = "",
    val name: String = "",
    val text: String? = null, // plain_text 变量的值；其余类型为 nil
) {
    val isSecret: Boolean get() = type == "secret_text" || type == "secrets_store_secret"
    val isPlainText: Boolean get() = type == "plain_text"

    /** 回传时转为 inherit（按名保留旧绑定，密钥值我们读不到也能保住）。 */
    fun asInherit(): WorkerBindingInput = WorkerBindingInput(type = "inherit", name = name)
}

/** 脚本设置（GET .../settings）。 */
@Serializable
data class WorkerSettings(
    val bindings: List<WorkerBinding> = emptyList(),
    @SerialName("compatibility_date") val compatibilityDate: String? = null,
    @SerialName("compatibility_flags") val compatibilityFlags: List<String>? = null,
    @SerialName("usage_model") val usageModel: String? = null,
    val logpush: Boolean? = null,
) {
    /** 过滤掉空名（容错解码降级）的有效绑定。 */
    val validBindings: List<WorkerBinding> get() = bindings.filter { it.name.isNotEmpty() }

    /** 把现有绑定整组转为 inherit，供「只改某个变量、其余保持」的安全回传。 */
    fun inheritedBindings(excludingName: String? = null): List<WorkerBindingInput> =
        validBindings.filter { it.name != excludingName }.map { it.asInherit() }
}

// MARK: - 上传 / 写入请求体

/** PATCH settings 的单条绑定。inherit 只发 {type,name}；plain_text 发 {type,name,text}。 */
@Serializable
data class WorkerBindingInput(
    val type: String,
    val name: String,
    val text: String? = null,
)

/** PATCH settings 的 settings part（改变量时回传：变更项 + 其余 inherit）。 */
@Serializable
data class WorkerSettingsPatch(
    val bindings: List<WorkerBindingInput>,
    @SerialName("compatibility_date") val compatibilityDate: String? = null,
    @SerialName("compatibility_flags") val compatibilityFlags: List<String>? = null,
)

// MARK: - 密钥

/** 密钥（GET .../secrets，仅名 + 类型，永不含值）。 */
@Serializable
data class WorkerSecret(
    val name: String = "",
    val type: String? = null,
)

/** 新建 / 更新密钥（PUT .../secrets）。 */
@Serializable
data class WorkerSecretInput(
    val name: String,
    val text: String,
    val type: String = "secret_text",
)

// MARK: - Cron 触发器

/** 单条 Cron 触发器（GET .../schedules）。 */
@Serializable
data class WorkerSchedule(
    val cron: String = "",
    @SerialName("created_on") val createdOn: String? = null,
    @SerialName("modified_on") val modifiedOn: String? = null,
)

/** schedules 端点 result 形态 { schedules: [...] }。 */
@Serializable
data class WorkerSchedulesResult(
    val schedules: List<WorkerSchedule> = emptyList(),
)

/** PUT .../schedules 的单条（整组替换，请求体是裸数组 [{cron}]）。 */
@Serializable
data class WorkerScheduleInput(val cron: String)
