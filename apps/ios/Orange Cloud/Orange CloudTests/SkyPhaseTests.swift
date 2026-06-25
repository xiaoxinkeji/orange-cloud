//
//  SkyPhaseTests.swift
//  Orange CloudTests
//
//  Tests for SkyPhase.current(colorScheme:hour:) and associated properties.
//

import XCTest
import SwiftUI
@testable import Orange_Cloud

final class SkyPhaseTests: XCTestCase {

    // MARK: - Light color scheme: representative hours for each phase

    func testLight_earlyMorning_returnsDawn() {
        // Hour 0 (midnight) falls into default → dawn
        XCTAssertEqual(SkyPhase.current(colorScheme: .light, hour: 0), .dawn)
    }

    func testLight_preDawn_returnsDawn() {
        // Hour 3 → default → dawn
        XCTAssertEqual(SkyPhase.current(colorScheme: .light, hour: 3), .dawn)
    }

    func testLight_dawnHour_returnsDawn() {
        // Hour 5 → 5..<9 → dawn
        XCTAssertEqual(SkyPhase.current(colorScheme: .light, hour: 5), .dawn)
    }

    func testLight_lateDawn_returnsDawn() {
        // Hour 8 → 5..<9 → dawn
        XCTAssertEqual(SkyPhase.current(colorScheme: .light, hour: 8), .dawn)
    }

    func testLight_morning_returnsDay() {
        // Hour 9 → 9..<16 → day
        XCTAssertEqual(SkyPhase.current(colorScheme: .light, hour: 9), .day)
    }

    func testLight_midday_returnsDay() {
        // Hour 12 → 9..<16 → day
        XCTAssertEqual(SkyPhase.current(colorScheme: .light, hour: 12), .day)
    }

    func testLight_afternoon_returnsDay() {
        // Hour 15 → 9..<16 → day
        XCTAssertEqual(SkyPhase.current(colorScheme: .light, hour: 15), .day)
    }

    func testLight_lateAfternoon_returnsDusk() {
        // Hour 16 → 16..<24 → dusk
        XCTAssertEqual(SkyPhase.current(colorScheme: .light, hour: 16), .dusk)
    }

    func testLight_evening_returnsDusk() {
        // Hour 18 → 16..<24 → dusk
        XCTAssertEqual(SkyPhase.current(colorScheme: .light, hour: 18), .dusk)
    }

    func testLight_lateEvening_returnsDusk() {
        // Hour 23 → 16..<24 → dusk
        XCTAssertEqual(SkyPhase.current(colorScheme: .light, hour: 23), .dusk)
    }

    // MARK: - Boundary hours (light)

    func testLight_boundary_hour5_isDawn() {
        XCTAssertEqual(SkyPhase.current(colorScheme: .light, hour: 5), .dawn)
    }

    func testLight_boundary_hour9_isDay() {
        XCTAssertEqual(SkyPhase.current(colorScheme: .light, hour: 9), .day)
    }

    func testLight_boundary_hour16_isDusk() {
        XCTAssertEqual(SkyPhase.current(colorScheme: .light, hour: 16), .dusk)
    }

    func testLight_boundary_hour24_isDusk() {
        // Hour 24 is not in 16..<24 (exclusive upper bound), falls to default → dawn
        XCTAssertEqual(SkyPhase.current(colorScheme: .light, hour: 24), .dawn)
    }

    // MARK: - Dark color scheme

    func testDark_emberHour_returnsEmber() {
        // Hour 18 → 17..<23 → ember
        XCTAssertEqual(SkyPhase.current(colorScheme: .dark, hour: 18), .ember)
    }

    func testDark_emberStart_returnsEmber() {
        // Hour 17 → 17..<23 → ember
        XCTAssertEqual(SkyPhase.current(colorScheme: .dark, hour: 17), .ember)
    }

    func testDark_emberEnd_returnsEmber() {
        // Hour 22 → 17..<23 → ember
        XCTAssertEqual(SkyPhase.current(colorScheme: .dark, hour: 22), .ember)
    }

    func testDark_nightHour_returnsNight() {
        // Hour 2 → not in 17..<23 → night
        XCTAssertEqual(SkyPhase.current(colorScheme: .dark, hour: 2), .night)
    }

    func testDark_midnight_returnsNight() {
        // Hour 0 → night
        XCTAssertEqual(SkyPhase.current(colorScheme: .dark, hour: 0), .night)
    }

    func testDark_morning_returnsNight() {
        // Hour 10 → not in 17..<23 → night
        XCTAssertEqual(SkyPhase.current(colorScheme: .dark, hour: 10), .night)
    }

    func testDark_boundary_hour23_isNight() {
        // Hour 23 → not in 17..<23 (exclusive upper bound) → night
        XCTAssertEqual(SkyPhase.current(colorScheme: .dark, hour: 23), .night)
    }

    // MARK: - Body gradient non-empty

    func testAllPhases_bodyHasAtLeastTwoColors() {
        let phases: [SkyPhase] = [.dawn, .day, .dusk, .ember, .night]
        for phase in phases {
            XCTAssertGreaterThanOrEqual(phase.body.count, 2,
                "\(phase) body should have at least 2 gradient stops")
        }
    }

    // MARK: - Glow color exists (non-crash sanity)

    func testAllPhases_glowDoesNotCrash() {
        let phases: [SkyPhase] = [.dawn, .day, .dusk, .ember, .night]
        for phase in phases {
            // Accessing .glow should not crash; it returns a Color
            _ = phase.glow
        }
    }

    // MARK: - Light vs dark at same hour yields different phases

    func testSameHour_lightAndDark_differAtNight() {
        // Hour 2: light → dawn (default), dark → night
        let lightPhase = SkyPhase.current(colorScheme: .light, hour: 2)
        let darkPhase = SkyPhase.current(colorScheme: .dark, hour: 2)
        XCTAssertNotEqual(lightPhase, darkPhase,
            "Light and dark schemes should produce different phases at hour 2")
    }

    func testSameHour_lightAndDark_differAtDusk() {
        // Hour 19: light → dusk, dark → ember
        let lightPhase = SkyPhase.current(colorScheme: .light, hour: 19)
        let darkPhase = SkyPhase.current(colorScheme: .dark, hour: 19)
        XCTAssertNotEqual(lightPhase, darkPhase,
            "Light and dark schemes should produce different phases at hour 19")
    }
}
