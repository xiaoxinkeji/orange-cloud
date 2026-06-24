//
//  SSLCertificateService.swift
//  Orange Cloud
//
//  SSL/TLS 证书：Universal SSL、边缘证书、自定义证书。
//

import Foundation

struct SSLCertificateService {

    private let client: CFAPIClient

    init(client: CFAPIClient) {
        self.client = client
    }

    func getUniversalSSL(zoneId: String) async throws -> UniversalSSL {
        let response: CFAPIResponse<UniversalSSL> = try await client.get(
            "zones/\(zoneId)/ssl/universal/settings"
        )
        guard response.success, let result = response.result else {
            throw response.toAPIError()
        }
        return result
    }

    func listEdgeCertificates(zoneId: String) async throws -> [EdgeCertificate] {
        let response: CFAPIResponseArray<EdgeCertificate> = try await client.get(
            "zones/\(zoneId)/ssl/certificate_packs"
        )
        guard response.success else {
            throw response.toAPIError()
        }
        return response.result ?? []
    }

    func listCustomCertificates(zoneId: String) async throws -> [CustomCertificate] {
        let response: CFAPIResponseArray<CustomCertificate> = try await client.get(
            "zones/\(zoneId)/custom_certificates"
        )
        guard response.success else {
            throw response.toAPIError()
        }
        return response.result ?? []
    }
}
