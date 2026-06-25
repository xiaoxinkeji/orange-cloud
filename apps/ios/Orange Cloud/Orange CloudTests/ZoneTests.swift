//
//  ZoneTests.swift
//  Orange CloudTests
//
//  Tests for Zone and ZonePlan model decoding.
//

import XCTest
@testable import Orange_Cloud

final class ZoneTests: XCTestCase {

    // MARK: - Full zone decoding

    func testDecodeFullZone() throws {
        let json = """
        {
            "id": "abc123def456",
            "name": "example.com",
            "status": "active",
            "plan": { "name": "free" },
            "name_servers": ["ada.ns.cloudflare.com", "bob.ns.cloudflare.com"]
        }
        """.data(using: .utf8)!

        let zone = try JSONDecoder().decode(Zone.self, from: json)

        XCTAssertEqual(zone.id, "abc123def456")
        XCTAssertEqual(zone.name, "example.com")
        XCTAssertEqual(zone.status, "active")
        XCTAssertNotNil(zone.plan)
        XCTAssertEqual(zone.plan?.name, "free")
        XCTAssertEqual(zone.nameServers?.count, 2)
        XCTAssertEqual(zone.nameServers?[0], "ada.ns.cloudflare.com")
        XCTAssertEqual(zone.nameServers?[1], "bob.ns.cloudflare.com")
    }

    // MARK: - Plan name extraction

    func testPlanName_pro() throws {
        let json = """
        {
            "id": "z1",
            "name": "pro-site.com",
            "status": "active",
            "plan": { "name": "pro" }
        }
        """.data(using: .utf8)!

        let zone = try JSONDecoder().decode(Zone.self, from: json)
        XCTAssertEqual(zone.plan?.name, "pro")
    }

    func testPlanName_business() throws {
        let json = """
        {
            "id": "z2",
            "name": "biz-site.com",
            "status": "active",
            "plan": { "name": "business" }
        }
        """.data(using: .utf8)!

        let zone = try JSONDecoder().decode(Zone.self, from: json)
        XCTAssertEqual(zone.plan?.name, "business")
    }

    func testPlanName_enterprise() throws {
        let json = """
        {
            "id": "z3",
            "name": "ent-site.com",
            "status": "active",
            "plan": { "name": "enterprise" }
        }
        """.data(using: .utf8)!

        let zone = try JSONDecoder().decode(Zone.self, from: json)
        XCTAssertEqual(zone.plan?.name, "enterprise")
    }

    // MARK: - Missing optional fields

    func testDecodeZoneWithoutPlan() throws {
        let json = """
        {
            "id": "z-noplan",
            "name": "noplan.com",
            "status": "pending"
        }
        """.data(using: .utf8)!

        let zone = try JSONDecoder().decode(Zone.self, from: json)

        XCTAssertEqual(zone.id, "z-noplan")
        XCTAssertEqual(zone.name, "noplan.com")
        XCTAssertEqual(zone.status, "pending")
        XCTAssertNil(zone.plan)
    }

    func testDecodeZoneWithoutNameServers() throws {
        let json = """
        {
            "id": "z-nons",
            "name": "nons.com",
            "status": "paused",
            "plan": { "name": "free" }
        }
        """.data(using: .utf8)!

        let zone = try JSONDecoder().decode(Zone.self, from: json)

        XCTAssertNil(zone.nameServers)
    }

    // MARK: - Nameserver array

    func testNameServers_singleEntry() throws {
        let json = """
        {
            "id": "z-single",
            "name": "single.com",
            "status": "active",
            "name_servers": ["only.ns.cloudflare.com"]
        }
        """.data(using: .utf8)!

        let zone = try JSONDecoder().decode(Zone.self, from: json)
        XCTAssertEqual(zone.nameServers?.count, 1)
        XCTAssertEqual(zone.nameServers?.first, "only.ns.cloudflare.com")
    }

    func testNameServers_emptyArray() throws {
        let json = """
        {
            "id": "z-empty",
            "name": "empty.com",
            "status": "active",
            "name_servers": []
        }
        """.data(using: .utf8)!

        let zone = try JSONDecoder().decode(Zone.self, from: json)
        XCTAssertNotNil(zone.nameServers)
        XCTAssertEqual(zone.nameServers?.count, 0)
    }

    // MARK: - Status values

    func testDecodeZoneStatusPending() throws {
        let json = """
        {
            "id": "z-pending",
            "name": "pending.com",
            "status": "pending"
        }
        """.data(using: .utf8)!

        let zone = try JSONDecoder().decode(Zone.self, from: json)
        XCTAssertEqual(zone.status, "pending")
    }

    func testDecodeZoneStatusPaused() throws {
        let json = """
        {
            "id": "z-paused",
            "name": "paused.com",
            "status": "paused"
        }
        """.data(using: .utf8)!

        let zone = try JSONDecoder().decode(Zone.self, from: json)
        XCTAssertEqual(zone.status, "paused")
    }

    // MARK: - Hashable / Identifiable conformance

    func testZoneIdentifiable() throws {
        let json = """
        {
            "id": "unique-id-123",
            "name": "test.com",
            "status": "active"
        }
        """.data(using: .utf8)!

        let zone = try JSONDecoder().decode(Zone.self, from: json)
        XCTAssertEqual(zone.id, "unique-id-123")
    }

    func testZoneEquality() throws {
        let json = """
        {
            "id": "eq-id",
            "name": "eq.com",
            "status": "active",
            "plan": { "name": "free" },
            "name_servers": ["ns1.cf.com"]
        }
        """.data(using: .utf8)!

        let zone1 = try JSONDecoder().decode(Zone.self, from: json)
        let zone2 = try JSONDecoder().decode(Zone.self, from: json)
        XCTAssertEqual(zone1, zone2)
    }

    func testZoneHashable_inSet() throws {
        let json = """
        {
            "id": "hash-id",
            "name": "hash.com",
            "status": "active",
            "plan": { "name": "free" }
        }
        """.data(using: .utf8)!

        let zone = try JSONDecoder().decode(Zone.self, from: json)
        var zoneSet = Set<Zone>()
        zoneSet.insert(zone)
        zoneSet.insert(zone)
        XCTAssertEqual(zoneSet.count, 1, "Inserting the same zone twice should result in count 1")
    }

    // MARK: - Round-trip encoding/decoding

    func testZoneRoundTrip() throws {
        let json = """
        {
            "id": "rt-id",
            "name": "roundtrip.com",
            "status": "active",
            "plan": { "name": "pro" },
            "name_servers": ["ns1.cf.com", "ns2.cf.com"]
        }
        """.data(using: .utf8)!

        let original = try JSONDecoder().decode(Zone.self, from: json)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Zone.self, from: encoded)

        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.name, "roundtrip.com")
        XCTAssertEqual(decoded.plan?.name, "pro")
        XCTAssertEqual(decoded.nameServers?.count, 2)
    }
}
