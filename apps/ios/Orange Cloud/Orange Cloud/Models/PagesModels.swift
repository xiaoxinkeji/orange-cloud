//
//  PagesModels.swift
//  Orange Cloud
//
//  Cloudflare Pages锛坅ccount 绾э級锛氶」鐩?+ 閮ㄧ讲銆傝 page.read锛屽啓 page.write銆?
//  瀛楁鍚嶆牳瀵硅嚜 Cloudflare 瀹樻柟 SDK锛坈loudflare-python types/pages锛夈€?
//  娉ㄦ剰锛欸ET 椤圭洰鏃?secret_text 绫诲瀷鐨勭幆澧冨彉閲?value 涓?null锛堝凡鑴辨晱锛夛紝鏁?App 鍐呯幆澧冨彉閲忓彧璇诲睍绀恒€?
//

import Foundation

// MARK: - 椤圭洰

nonisolated struct PagesProject: Codable, Identifiable, Sendable {
    let name:              String
    let subdomain:         String?
    let domains:           [String]?
    let productionBranch:  String?
    let createdOn:         String?
    let buildConfig:       PagesBuildConfig?
    let deploymentConfigs: PagesDeploymentConfigs?
    let latestDeployment:  PagesDeployment?
    let source:            PagesSource?

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, subdomain, domains, source
        case productionBranch  = "production_branch"
        case createdOn         = "created_on"
        case buildConfig       = "build_config"
        case deploymentConfigs = "deployment_configs"
        case latestDeployment  = "latest_deployment"
    }
}

nonisolated struct PagesBuildConfig: Codable, Sendable {
    var buildCommand:   String?
    var destinationDir: String?
    var rootDir:        String?

    enum CodingKeys: String, CodingKey {
        case buildCommand   = "build_command"
        case destinationDir = "destination_dir"
        case rootDir        = "root_dir"
    }
}

nonisolated struct PagesDeploymentConfigs: Codable, Sendable {
    var production: PagesEnvConfig?
    var preview:    PagesEnvConfig?
}

nonisolated struct PagesEnvConfig: Codable, Sendable {
    var envVars: [String: PagesEnvVar]?

    enum CodingKeys: String, CodingKey {
        case envVars = "env_vars"
    }
}

nonisolated struct PagesEnvVar: Codable, Sendable {
    var type:  String?     // plain_text | secret_text
    var value: String?     // secret_text 鏃朵负 null

    var isSecret: Bool { type == "secret_text" }
}

nonisolated struct PagesSource: Codable, Sendable {
    let type:   String?    // github | gitlab
    let config: PagesSourceConfig?
}

nonisolated struct PagesSourceConfig: Codable, Sendable {
    let owner:            String?
    let repoName:         String?
    let productionBranch: String?

    enum CodingKeys: String, CodingKey {
        case owner
        case repoName         = "repo_name"
        case productionBranch = "production_branch"
    }

    /// owner/repo 灞曠ず
    var repoLabel: String? {
        guard let repoName else { return nil }
        return owner.map { "\($0)/\(repoName)" } ?? repoName
    }
}

// MARK: - 閮ㄧ讲

nonisolated struct PagesDeployment: Codable, Identifiable, Sendable {
    let id:                String
    let shortId:           String?
    let projectName:       String?
    let environment:       String?    // production | preview
    let url:               String?
    let createdOn:         String?
    let modifiedOn:        String?
    let aliases:           [String]?
    let isSkipped:         Bool?
    let latestStage:       PagesStage?
    let stages:            [PagesStage]?
    let deploymentTrigger: PagesDeploymentTrigger?

    enum CodingKeys: String, CodingKey {
        case id, environment, url, stages, aliases
        case shortId           = "short_id"
        case projectName       = "project_name"
        case createdOn         = "created_on"
        case modifiedOn        = "modified_on"
        case isSkipped         = "is_skipped"
        case latestStage       = "latest_stage"
        case deploymentTrigger = "deployment_trigger"
    }

    /// 鏁翠綋鐘舵€侊紙鍙栨渶鏂伴樁娈碉級
    var status: PagesDeployStatus { PagesDeployStatus(rawValue: latestStage?.status ?? "") ?? .unknown }

    var isProduction: Bool { environment == "production" }
}

nonisolated struct PagesStage: Codable, Identifiable, Sendable {
    let name:      String?
    let status:    String?    // success | idle | active | failure | canceled
    let startedOn: String?
    let endedOn:   String?

    var id: String { name ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case name, status
        case startedOn = "started_on"
        case endedOn   = "ended_on"
    }

    var statusValue: PagesDeployStatus { PagesDeployStatus(rawValue: status ?? "") ?? .unknown }
}

nonisolated struct PagesDeploymentTrigger: Codable, Sendable {
    let type:     String?
    let metadata: PagesTriggerMetadata?
}

nonisolated struct PagesTriggerMetadata: Codable, Sendable {
    let branch:        String?
    let commitHash:    String?
    let commitMessage: String?

    enum CodingKeys: String, CodingKey {
        case branch
        case commitHash    = "commit_hash"
        case commitMessage = "commit_message"
    }

    /// 鐭搱甯?
    var shortHash: String? { commitHash.map { String($0.prefix(8)) } }
}

// MARK: - 閮ㄧ讲鐘舵€?

nonisolated enum PagesDeployStatus: String, Sendable {
    case success, idle, active, failure, canceled
    case unknown = ""

    var label: String {
        switch self {
        case .success:  String(localized: "鎴愬姛")
        case .idle:     String(localized: "鎺掗槦涓?)
        case .active:   String(localized: "杩涜涓?)
        case .failure:  String(localized: "澶辫触")
        case .canceled: String(localized: "宸插彇娑?)
        case .unknown:  String(localized: "鏈煡")
        }
    }
}

// MARK: - 鑷畾涔夊煙鍚?

/// 椤圭洰鑷畾涔夊煙鍚嶃€侴ET /accounts/{id}/pages/projects/{name}/domains
nonisolated struct PagesDomain: Codable, Identifiable, Sendable {
    let id:                   String
    let name:                 String
    let status:               String?   // initializing | pending | active | deactivated | blocked | error
    let zoneTag:              String?   // 鍩熷悕鎵€鍦?Zone锛堝湪褰撳墠 Cloudflare 涓婃墠鏈夋剰涔夛級
    let createdOn:            String?
    let certificateAuthority: String?
    let validationData:       PagesDomainValidationData?
    let verificationData:     PagesDomainVerificationData?

    enum CodingKeys: String, CodingKey {
        case id, name, status
        case zoneTag              = "zone_tag"
        case createdOn            = "created_on"
        case certificateAuthority = "certificate_authority"
        case validationData       = "validation_data"
        case verificationData     = "verification_data"
    }

    var statusValue: PagesDomainStatus { PagesDomainStatus(rawValue: status ?? "") ?? .unknown }
}

/// 璇佷功楠岃瘉淇℃伅锛坢ethod == txt 鏃剁粰鍑哄緟娣诲姞鐨?TXT 璁板綍锛?
nonisolated struct PagesDomainValidationData: Codable, Sendable {
    let status:       String?
    let method:       String?    // http | txt
    let txtName:      String?
    let txtValue:     String?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case status, method
        case txtName      = "txt_name"
        case txtValue     = "txt_value"
        case errorMessage = "error_message"
    }
}

/// 鍩熷悕褰掑睘楠岃瘉淇℃伅
nonisolated struct PagesDomainVerificationData: Codable, Sendable {
    let status:       String?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case status
        case errorMessage = "error_message"
    }
}

nonisolated enum PagesDomainStatus: String, Sendable {
    case initializing, pending, active, deactivated, blocked, error
    case unknown = ""

    var label: String {
        switch self {
        case .active:       String(localized: "鐢熸晥涓?)
        case .pending:      String(localized: "楠岃瘉涓?)
        case .initializing: String(localized: "鍒濆鍖?)
        case .deactivated:  String(localized: "宸插仠鐢?)
        case .blocked:      String(localized: "宸插皝閿?)
        case .error:        String(localized: "閿欒")
        case .unknown:      String(localized: "鏈煡")
        }
    }
}

/// POST .../domains 璇锋眰浣?
nonisolated struct PagesDomainAddRequest: Codable, Sendable {
    let name: String
}

// MARK: - 鍐欏叆杞借嵎

/// PATCH 椤圭洰锛氫粎浼犺鏀圭殑瀛楁锛堥《灞傚悎骞讹紝鐪佺暐瀛楁涓嶅彉锛夈€傜幆澧冨彉閲忎笉鍦ㄦ锛堣劚鏁忛闄╋紝App 鍐呭彧璇伙級銆?
nonisolated struct PagesProjectUpdate: Codable, Sendable {
    var buildConfig:      PagesBuildConfig?
    var productionBranch: String?

    enum CodingKeys: String, CodingKey {
        case buildConfig      = "build_config"
        case productionBranch = "production_branch"
    }
}

/// POST /accounts/{id}/pages/projects 璇锋眰浣撱€備粎寤轰竴涓?Direct Upload 绌洪」鐩?
/// 锛堟墜鏈虹鏃犳硶涓婁紶鏋勫缓浜х墿 / 杩?Git锛屽缓鍚庨渶鐢?Wrangler 鎴?Dashboard 閮ㄧ讲锛夈€?
nonisolated struct PagesCreateRequest: Codable, Sendable {
    let name:             String
    let productionBranch: String

    enum CodingKeys: String, CodingKey {
        case name
        case productionBranch = "production_branch"
    }
}

/// retry / rollback 鐨勭┖ POST 浣?
nonisolated struct PagesEmptyBody: Codable, Sendable {}

// MARK: - 鐩存帴涓婁紶閮ㄧ讲锛圖irect Upload锛?

/// GET .../upload-token 鐨?result锛堣祫婧愪笂浼犵敤鐨勭煭鏈?JWT锛?
nonisolated struct PagesUploadToken: Codable, Sendable {
    let jwt: String
}

/// POST /pages/assets/upload 鐨勫崟鏉¤浇鑽凤紙key=璧勬簮鍝堝笇锛寁alue=base64 鍐呭锛?
nonisolated struct PagesAssetUpload: Codable, Sendable {
    let key:      String
    let value:    String
    let metadata: PagesAssetMetadata
    let base64:   Bool
}

nonisolated struct PagesAssetMetadata: Codable, Sendable {
    let contentType: String     // CF 鏈熸湜 camelCase contentType
}

/// check-missing / upsert-hashes 鐨勮姹備綋
nonisolated struct PagesHashesBody: Codable, Sendable {
    let hashes: [String]
}

/// 寰呴儴缃茬殑鍗曚釜鏂囦欢銆俻ath 浠?/ 寮€澶达紙濡?/index.html锛夛紱contentType 鎸夋墿灞曞悕鎺ㄦ柇銆?
nonisolated struct PagesDeployFile: Sendable, Identifiable {
    let path: String
    let data: Data

    var id: String { path }
    var contentType: String { PagesMime.type(forPath: path) }
}

/// 鎸夋墿灞曞悕鎺ㄦ柇 MIME锛堣鐩栧父瑙侀潤鎬佽祫婧愶紝鍏朵綑鍥為€€ octet-stream锛?
nonisolated enum PagesMime {
    static func type(forPath path: String) -> String {
        switch (path as NSString).pathExtension.lowercased() {
        case "html", "htm":   "text/html"
        case "css":           "text/css"
        case "js", "mjs":     "application/javascript"
        case "json":          "application/json"
        case "map":           "application/json"
        case "webmanifest":   "application/manifest+json"
        case "svg":           "image/svg+xml"
        case "png":           "image/png"
        case "jpg", "jpeg":   "image/jpeg"
        case "gif":           "image/gif"
        case "webp":          "image/webp"
        case "avif":          "image/avif"
        case "ico":           "image/x-icon"
        case "txt":           "text/plain"
        case "md":            "text/markdown"
        case "xml":           "application/xml"
        case "pdf":           "application/pdf"
        case "wasm":          "application/wasm"
        case "woff":          "font/woff"
        case "woff2":         "font/woff2"
        case "ttf":           "font/ttf"
        case "otf":           "font/otf"
        default:              "application/octet-stream"
        }
    }
}
