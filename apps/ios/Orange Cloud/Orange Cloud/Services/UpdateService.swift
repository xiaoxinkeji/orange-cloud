//
//  UpdateService.swift
//  Orange Cloud
//
//  检查 GitHub Releases 是否有新版本。
//

import Foundation

struct UpdateService {

    enum UpdateResult: Equatable, Sendable {
        case upToDate
        case updateAvailable(version: String, url: String)
        case error(String)
        case unknown
    }

    private static let releasesURL = URL(string: "https://api.github.com/repos/xiaoxinkeji/orange-cloud/releases/latest")!

    static func checkForUpdate() async -> UpdateResult {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let current = parseVersion(currentVersion)
        guard current.count > 0 else { return .unknown }

        var request = URLRequest(url: releasesURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let data: Data
        let httpResponse: HTTPURLResponse
        do {
            let (d, r) = try await URLSession.shared.data(for: request)
            data = d
            guard let hr = r as? HTTPURLResponse else {
                return .error("非 HTTP 响应")
            }
            httpResponse = hr
        } catch {
            return .error(error.localizedDescription)
        }

        guard httpResponse.statusCode == 200 else {
            return .error("HTTP \(httpResponse.statusCode)")
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let release = try decoder.decode(GitHubRelease.self, from: data)
            let tag = release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName
            let latest = parseVersion(tag)

            if compareVersions(latest, current) > 0 {
                return .updateAvailable(
                    version: release.tagName,
                    url: release.htmlUrl
                )
            }
            return .upToDate
        } catch {
            return .error(error.localizedDescription)
        }
    }

    private static func parseVersion(_ s: String) -> [Int] {
        s.split(separator: ".", omittingEmptySubsequences: false)
            .compactMap { Int($0) }
    }

    private static func compareVersions(_ a: [Int], _ b: [Int]) -> Int {
        let maxLen = max(a.count, b.count)
        for i in 0..<maxLen {
            let va = i < a.count ? a[i] : 0
            let vb = i < b.count ? b[i] : 0
            if va < vb { return -1 }
            if va > vb { return 1 }
        }
        return 0
    }

    private nonisolated struct GitHubRelease: Codable, Sendable {
        let tagName: String
        let htmlUrl: String
    }
}
