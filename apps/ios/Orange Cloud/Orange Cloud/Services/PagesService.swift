//
//  PagesService.swift
//  Orange Cloud
//
//  Cloudflare Pages API：项目列表、部署、域名、重新部署。
//

import Foundation

struct PagesService {

    private let client: CFAPIClient

    init(client: CFAPIClient) {
        self.client = client
    }

    func listProjects(accountId: String) async throws -> [PagesProject] {
        let response: CFAPIResponseArray<PagesProject> = try await client.get(
            "accounts/\(accountId)/pages/projects"
        )
        guard response.success else {
            throw response.toAPIError()
        }
        return response.result ?? []
    }

    func getProject(accountId: String, projectName: String) async throws -> PagesProject {
        let response: CFAPIResponse<PagesProject> = try await client.get(
            "accounts/\(accountId)/pages/projects/\(projectName)"
        )
        guard response.success, let project = response.result else {
            throw response.toAPIError()
        }
        return project
    }

    func listDeployments(accountId: String, projectName: String) async throws -> [PagesDeployment] {
        let response: CFAPIResponseArray<PagesDeployment> = try await client.get(
            "accounts/\(accountId)/pages/projects/\(projectName)/deployments",
            queryItems: [URLQueryItem(name: "per_page", value: "25")]
        )
        guard response.success else {
            throw response.toAPIError()
        }
        return response.result ?? []
    }

    func getDeployment(accountId: String, projectName: String, deploymentId: String) async throws -> PagesDeployment {
        let response: CFAPIResponse<PagesDeployment> = try await client.get(
            "accounts/\(accountId)/pages/projects/\(projectName)/deployments/\(deploymentId)"
        )
        guard response.success, let deployment = response.result else {
            throw response.toAPIError()
        }
        return deployment
    }

    func listDomains(accountId: String, projectName: String) async throws -> [PagesDomain] {
        let response: CFAPIResponseArray<PagesDomain> = try await client.get(
            "accounts/\(accountId)/pages/projects/\(projectName)/domains"
        )
        guard response.success else {
            throw response.toAPIError()
        }
        return response.result ?? []
    }

    func retryDeployment(accountId: String, projectName: String, deploymentId: String) async throws -> PagesDeployment {
        let response: CFAPIResponse<PagesDeployment> = try await client.post(
            "accounts/\(accountId)/pages/projects/\(projectName)/deployments/\(deploymentId)/retry",
            body: EmptyBody()
        )
        guard response.success, let deployment = response.result else {
            throw response.toAPIError()
        }
        return deployment
    }

    func triggerDeploy(accountId: String, projectName: String, branch: String) async throws -> PagesDeployment {
        let response: CFAPIResponse<PagesDeployment> = try await client.post(
            "accounts/\(accountId)/pages/projects/\(projectName)/deployments",
            body: PagesTriggerDeploy(branch: branch)
        )
        guard response.success, let deployment = response.result else {
            throw response.toAPIError()
        }
        return deployment
    }
}

private nonisolated struct EmptyBody: Codable, Sendable {}

private nonisolated struct PagesTriggerDeploy: Codable, Sendable {
    let branch: String
}
