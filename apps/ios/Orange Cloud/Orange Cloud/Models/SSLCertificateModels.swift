//
//  SSLCertificateModels.swift
//  Orange Cloud
//
//  SSL/TLS 证书模型：边缘证书、自定义证书、Universal SSL 状态。
//

import Foundation

nonisolated struct UniversalSSL: Codable, Sendable {
    let enabled: Bool
}

nonisolated struct EdgeCertificate: Codable, Identifiable, Sendable {
    let id: String
    let type: String?
    let hosts: [String]?
    let status: String?
    let primaryCertificate: String?
    let validationMethod: String?
    let validityDays: Int?
    let certificateAuthority: String?
    let expiresOn: String?

    var isActive: Bool { status == "active" }
    var isExpired: Bool { status == "expired" }

    enum CodingKeys: String, CodingKey {
        case id, type, hosts, status
        case primaryCertificate = "primary_certificate"
        case validationMethod = "validation_method"
        case validityDays = "validity_days"
        case certificateAuthority = "certificate_authority"
        case expiresOn = "expires_on"
    }
}

nonisolated struct CustomCertificate: Codable, Identifiable, Sendable {
    let id: String
    let hosts: [String]?
    let issuer: String?
    let signature: String?
    let status: String?
    let expiresOn: String?
    let uploadedOn: String?
    let keyType: String?

    var isActive: Bool { status == "active" }

    enum CodingKeys: String, CodingKey {
        case id, hosts, issuer, signature, status
        case expiresOn  = "expires_on"
        case uploadedOn = "uploaded_on"
        case keyType = "key_type"
    }
}

extension EdgeCertificate {
    static func parseDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.date(from: raw)
    }
}

extension CustomCertificate {
    static func parseDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.date(from: raw)
    }
}
