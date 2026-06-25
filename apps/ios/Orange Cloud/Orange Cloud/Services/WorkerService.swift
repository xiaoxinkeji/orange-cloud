//
//  WorkerService.swift
//  Orange Cloud
//

import Foundation

struct WorkerService {

    private let client: CFAPIClient

    init(client: CFAPIClient) {
        self.client = client
    }

    func listScripts(accountId: String) async throws -> [WorkerScript] {
        let response: CFAPIResponseArray<WorkerScript> = try await client.get(
            "accounts/\(accountId)/workers/scripts"
        )
        guard response.success else {
            throw response.toAPIError()
        }
        return response.result ?? []
    }

    // MARK: - 脚本内容

    func getScriptContent(accountId: String, scriptName: String) async throws -> String {
        let data = try await client.getRaw(
            "accounts/\(accountId)/workers/scripts/\(scriptName)",
            accept: "application/javascript"
        )
        guard let content = String(data: data, encoding: .utf8) else {
            throw APIError.decodingError(URLError(.cannotDecodeContentData))
        }
        return content
    }

    func updateScript(accountId: String, scriptName: String, content: String, metadata: WorkerScriptMetadata) async throws -> WorkerScript {
        var fields: [String: String] = [
            "metadata": metadata.jsonString,
        ]
        fields[metadata.bodyPart] = content
        let response: CFAPIResponse<WorkerScript> = try await client.putMultipart(
            "accounts/\(accountId)/workers/scripts/\(scriptName)",
            fields: fields
        )
        guard response.success, let result = response.result else {
            throw response.toAPIError()
        }
        return result
    }

    // MARK: - 路由

    func listRoutes(accountId: String) async throws -> [WorkerRoute] {
        let response: CFAPIResponseArray<WorkerRoute> = try await client.get(
            "accounts/\(accountId)/workers/routes"
        )
        guard response.success else {
            throw response.toAPIError()
        }
        return response.result ?? []
    }

    func updateRoutes(accountId: String, scriptName: String, routes: [WorkerRouteInput]) async throws {
        let body = WorkerRoutesUpdateRequest(routes: routes)
        let response: CFAPIResponse<EmptyResponse> = try await client.put(
            "accounts/\(accountId)/workers/scripts/\(scriptName)/routes",
            body: body
        )
        guard response.success else {
            throw response.toAPIError()
        }
    }

    // MARK: - 定时触发器

    func getSchedules(accountId: String, scriptName: String) async throws -> [WorkerSchedule] {
        let response: CFAPIResponse<WorkerScheduleList> = try await client.get(
            "accounts/\(accountId)/workers/scripts/\(scriptName)/schedules"
        )
        guard response.success, let result = response.result else {
            throw response.toAPIError()
        }
        return result.schedules ?? []
    }

    func updateSchedules(accountId: String, scriptName: String, schedules: [WorkerScheduleInput]) async throws {
        let body = WorkerSchedulesUpdateRequest(schedules: schedules)
        let response: CFAPIResponse<EmptyResponse> = try await client.put(
            "accounts/\(accountId)/workers/scripts/\(scriptName)/schedules",
            body: body
        )
        guard response.success else {
            throw response.toAPIError()
        }
    }

    // MARK: - 创建 / 删除

    func createScript(accountId: String, scriptName: String, content: String) async throws -> WorkerScript {
        let meta = WorkerScriptMetadata()
        var fields: [String: String] = [
            "metadata": meta.jsonString,
        ]
        fields[meta.bodyPart] = content
        let response: CFAPIResponse<WorkerScript> = try await client.putMultipart(
            "accounts/\(accountId)/workers/scripts/\(scriptName)",
            fields: fields
        )
        guard response.success, let result = response.result else {
            throw response.toAPIError()
        }
        return result
    }

    func deleteScript(accountId: String, scriptName: String) async throws {
        try await client.delete("accounts/\(accountId)/workers/scripts/\(scriptName)")
    }
}

// MARK: - 路由模型

nonisolated struct WorkerRoute: Codable, Identifiable, Sendable {
    let id: String?
    let pattern: String
    let script: String?
    let requestLimitFailOpen: Bool?

    enum CodingKeys: String, CodingKey {
        case id, pattern, script
        case requestLimitFailOpen = "request_limit_fail_open"
    }
}

nonisolated struct WorkerRouteInput: Codable, Sendable {
    let pattern: String
    let script: String?

    enum CodingKeys: String, CodingKey {
        case pattern, script
    }
}

private nonisolated struct WorkerRoutesUpdateRequest: Codable, Sendable {
    let routes: [WorkerRouteInput]
}

nonisolated struct WorkerScriptMetadata: Codable, Sendable {
    var bodyPart: String = "script"
    var bindings: [WorkerBinding]? = nil

    enum CodingKeys: String, CodingKey {
        case bodyPart = "body_part"
        case bindings
    }

    var jsonString: String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }
}

// MARK: - 定时触发器模型

nonisolated struct WorkerSchedule: Codable, Identifiable, Sendable {
    let cron: String
    let createdOn: String?
    let modifiedOn: String?

    var id: String { cron }

    enum CodingKeys: String, CodingKey {
        case cron
        case createdOn  = "created_on"
        case modifiedOn = "modified_on"
    }
}

nonisolated struct WorkerScheduleInput: Codable, Sendable {
    let cron: String
}

private nonisolated struct WorkerSchedulesUpdateRequest: Codable, Sendable {
    let schedules: [WorkerScheduleInput]
}

private nonisolated struct WorkerScheduleList: Codable, Sendable {
    let schedules: [WorkerSchedule]?
}

// MARK: - 绑定模型

nonisolated struct WorkerBinding: Codable, Identifiable, Sendable {
    let type: String
    let name: String
    let namespaceId: String?

    var id: String { "\(type)-\(name)" }

    enum CodingKeys: String, CodingKey {
        case type, name
        case namespaceId = "namespace_id"
    }
}
