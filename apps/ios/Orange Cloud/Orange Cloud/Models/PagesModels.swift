//
//  PagesModels.swift
//  Orange Cloud
//
//  Cloudflare Pages 项目、部署、域名模型。
//

import Foundation

nonisolated struct PagesProject: Codable, Identifiable, Hashable, Sendable {
    let name: String
    let subdomain: String?
    let domains: [String]?
    let source: PagesSource?
    let buildConfig: PagesBuildConfig?
    let deploymentConfigs: PagesDeploymentConfigs?
    let latestDeployment: PagesDeployment?
    let createdOn: String?
    let modifiedOn: String?

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, subdomain, domains, source
        case buildConfig = "build_config"
        case deploymentConfigs = "deployment_configs"
        case latestDeployment = "latest_deployment"
        case createdOn  = "created_on"
        case modifiedOn = "modified_on"
    }

    static func parseDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.date(from: raw) ?? {
            fmt.formatOptions = [.withInternetDateTime]
            return fmt.date(from: raw)
        }()
    }
}

nonisolated struct PagesSource: Codable, Hashable, Sendable {
    let type: String?
    let config: PagesSourceConfig?
}

nonisolated struct PagesSourceConfig: Codable, Hashable, Sendable {
    let owner: String?
    let repoName: String?
    let productionBranch: String?
    let prCommentsEnabled: Bool?
    let deploymentsEnabled: Bool?

    enum CodingKeys: String, CodingKey {
        case owner
        case repoName = "repo_name"
        case productionBranch = "production_branch"
        case prCommentsEnabled = "pr_comments_enabled"
        case deploymentsEnabled = "deployments_enabled"
    }
}

nonisolated struct PagesBuildConfig: Codable, Hashable, Sendable {
    let buildCommand: String?
    let destinationDir: String?
    let rootDir: String?
    let buildCaching: Bool?

    enum CodingKeys: String, CodingKey {
        case buildCommand  = "build_command"
        case destinationDir = "destination_dir"
        case rootDir = "root_dir"
        case buildCaching = "build_caching"
    }
}

nonisolated struct PagesDeploymentConfigs: Codable, Hashable, Sendable {
    let preview: PagesEnvConfig?
    let production: PagesEnvConfig?
}

nonisolated struct PagesEnvConfig: Codable, Hashable, Sendable {
    let envVars: [String: PagesEnvVar]?
    let compatibilityDate: String?
    let compatibilityFlags: [String]?

    enum CodingKeys: String, CodingKey {
        case envVars = "env_vars"
        case compatibilityDate = "compatibility_date"
        case compatibilityFlags = "compatibility_flags"
    }
}

nonisolated struct PagesEnvVar: Codable, Hashable, Sendable {
    let value: String?
    let type: String?
}

nonisolated struct PagesDeployment: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let shortId: String?
    let url: String?
    let environment: String?
    let stage: String?
    let latestStage: String?
    let deploymentTrigger: PagesDeploymentTrigger?
    let meta: PagesDeploymentMeta?
    let aliases: [String]?
    let createdOn: String?
    let modifiedOn: String?

    var isProduction: Bool { environment == "production" }
    var isPreview: Bool { environment == "preview" }

    enum CodingKeys: String, CodingKey {
        case id
        case shortId = "short_id"
        case url, environment, stage
        case latestStage = "latest_stage"
        case deploymentTrigger = "deployment_trigger"
        case meta, aliases
        case createdOn  = "created_on"
        case modifiedOn = "modified_on"
    }

    static func parseDate(_ raw: String?) -> Date? {
        PagesProject.parseDate(raw)
    }
}

nonisolated struct PagesDeploymentTrigger: Codable, Hashable, Sendable {
    let type: String?
    let metadata: String?
}

nonisolated struct PagesDeploymentMeta: Codable, Hashable, Sendable {
    let commitHash: String?
    let commitMessage: String?
    let branch: String?

    enum CodingKeys: String, CodingKey {
        case commitHash = "commit_hash"
        case commitMessage = "commit_message"
        case branch
    }
}

nonisolated struct PagesDomain: Codable, Identifiable, Hashable, Sendable {
    let name: String
    let status: String?
    let type: String?

    var id: String { name }
}
