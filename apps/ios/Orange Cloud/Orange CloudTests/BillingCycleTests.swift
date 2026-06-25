//
//  BillingCycleTests.swift
//  Orange CloudTests
//
//  Tests for BillingCycle.periodStart(billingDay:now:)
//

import XCTest
@testable import Orange_Cloud

final class BillingCycleTests: XCTestCase {

    // MARK: - Helpers

    /// Build a UTC date from components for deterministic testing.
    private func utcDate(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        return cal.date(from: comps)!
    }

    private func utcDay(_ date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.component(.day, from: date)
    }

    private func utcMonth(_ date: Date) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.component(.month, from: date)
    }

    // MARK: - Billing day = 1 (calendar month boundary)

    func testBillingDay1_midMonth_returnsCurrentMonthFirst() {
        // now = 2025-03-15, billing day = 1 → period start = 2025-03-01
        let now = utcDate(2025, 3, 15)
        let start = BillingCycle.periodStart(billingDay: 1, now: now)
        XCTAssertEqual(utcDay(start), 1)
        XCTAssertEqual(utcMonth(start), 3)
    }

    func testBillingDay1_onExactDay_returnsCurrentMonthFirst() {
        // now = 2025-06-01 12:00, billing day = 1 → period start = 2025-06-01
        let now = utcDate(2025, 6, 1)
        let start = BillingCycle.periodStart(billingDay: 1, now: now)
        XCTAssertEqual(utcDay(start), 1)
        XCTAssertEqual(utcMonth(start), 6)
    }

    // MARK: - Billing day = 15

    func testBillingDay15_afterBillingDay_returnsCurrentMonth15th() {
        // now = 2025-04-20, billing day = 15 → period start = 2025-04-15
        let now = utcDate(2025, 4, 20)
        let start = BillingCycle.periodStart(billingDay: 15, now: now)
        XCTAssertEqual(utcDay(start), 15)
        XCTAssertEqual(utcMonth(start), 4)
    }

    func testBillingDay15_beforeBillingDay_returnsPreviousMonth15th() {
        // now = 2025-04-10, billing day = 15 → period start = 2025-03-15
        let now = utcDate(2025, 4, 10)
        let start = BillingCycle.periodStart(billingDay: 15, now: now)
        XCTAssertEqual(utcDay(start), 15)
        XCTAssertEqual(utcMonth(start), 3)
    }

    func testBillingDay15_onExactDay_returnsCurrentMonth15th() {
        // now = 2025-07-15 12:00, billing day = 15 → thisMonth == now → return thisMonth
        let now = utcDate(2025, 7, 15)
        let start = BillingCycle.periodStart(billingDay: 15, now: now)
        XCTAssertEqual(utcDay(start), 15)
        XCTAssertEqual(utcMonth(start), 7)
    }

    // MARK: - Billing day > current day (falls back to previous month)

    func testBillingDay28_earlyInMonth_returnsPreviousMonth() {
        // now = 2025-05-03, billing day = 28 → period start = 2025-04-28
        let now = utcDate(2025, 5, 3)
        let start = BillingCycle.periodStart(billingDay: 28, now: now)
        XCTAssertEqual(utcDay(start), 28)
        XCTAssertEqual(utcMonth(start), 4)
    }

    // MARK: - Billing day = 28 (maximum clamped value)

    func testBillingDay28_lateInMonth_returnsCurrentMonth28th() {
        // now = 2025-08-30, billing day = 28 → period start = 2025-08-28
        let now = utcDate(2025, 8, 30)
        let start = BillingCycle.periodStart(billingDay: 28, now: now)
        XCTAssertEqual(utcDay(start), 28)
        XCTAssertEqual(utcMonth(start), 8)
    }

    // MARK: - Clamping: billing day out of range

    func testBillingDay0_clampsTo1() {
        // billingDay 0 should clamp to 1
        let now = utcDate(2025, 3, 15)
        let start = BillingCycle.periodStart(billingDay: 0, now: now)
        XCTAssertEqual(utcDay(start), 1)
        XCTAssertEqual(utcMonth(start), 3)
    }

    func testBillingDay31_clampsTo28() {
        // billingDay 31 should clamp to 28
        let now = utcDate(2025, 3, 30)
        let start = BillingCycle.periodStart(billingDay: 31, now: now)
        XCTAssertEqual(utcDay(start), 28)
        XCTAssertEqual(utcMonth(start), 3)
    }

    func testBillingDayNegative_clampsTo1() {
        // Negative billingDay clamps to 1
        let now = utcDate(2025, 6, 10)
        let start = BillingCycle.periodStart(billingDay: -5, now: now)
        XCTAssertEqual(utcDay(start), 1)
        XCTAssertEqual(utcMonth(start), 6)
    }

    // MARK: - Cross-year boundary (January → December)

    func testBillingDay15_januaryBeforeBillingDay_returnsDecemberPreviousYear() {
        // now = 2025-01-05, billing day = 15 → period start = 2024-12-15
        let now = utcDate(2025, 1, 5)
        let start = BillingCycle.periodStart(billingDay: 15, now: now)
        XCTAssertEqual(utcDay(start), 15)
        XCTAssertEqual(utcMonth(start), 12)

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        XCTAssertEqual(cal.component(.year, from: start), 2024)
    }

    // MARK: - Cross-month: March → February (handles short month)

    func testBillingDay28_marchEarly_returnsFebruary28() {
        // now = 2025-03-10, billing day = 28 → period start = 2025-02-28
        let now = utcDate(2025, 3, 10)
        let start = BillingCycle.periodStart(billingDay: 28, now: now)
        XCTAssertEqual(utcDay(start), 28)
        XCTAssertEqual(utcMonth(start), 2)
    }
}
