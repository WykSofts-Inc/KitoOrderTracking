//
//  KitoOrderShowcaseTests.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoOrderTracking

final class KitoOrderShowcaseTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testRemainingNeverNegative() {
        XCTAssertEqual(KitoETA.remaining(until: now.addingTimeInterval(90), now: now), 90)
        XCTAssertEqual(KitoETA.remaining(until: now.addingTimeInterval(-90), now: now), 0)
    }

    func testClock() {
        XCTAssertEqual(KitoETA.clock(725), "12:05")
        XCTAssertEqual(KitoETA.clock(3_725), "1:02:05")
        XCTAssertEqual(KitoETA.clock(0), "00:00")
    }

    func testMinutesText() {
        XCTAssertEqual(KitoETA.minutesText(10), "Arriving now")
        XCTAssertEqual(KitoETA.minutesText(61), "2 min")
        XCTAssertEqual(KitoETA.minutesText(12 * 60), "12 min")
        XCTAssertEqual(KitoETA.minutesText(65 * 60), "1 hr 5 min")
        XCTAssertEqual(KitoETA.minutesText(120 * 60), "2 hr")
    }

    func testElapsedFraction() {
        let start = now.addingTimeInterval(-600)
        let eta = now.addingTimeInterval(600)
        XCTAssertEqual(KitoETA.elapsedFraction(start: start, eta: eta, now: now), 0.5, accuracy: 0.0001)
        XCTAssertEqual(KitoETA.elapsedFraction(start: start, eta: eta, now: eta.addingTimeInterval(60)), 1)
        XCTAssertEqual(KitoETA.elapsedFraction(start: eta, eta: start, now: now), 1)
    }

    func testCourierHelpers() {
        let courier = KitoCourier(name: "Amara Mwangi", phone: "+254 712 345 678", rating: 4.86)
        XCTAssertEqual(courier.initials, "AM")
        XCTAssertEqual(courier.ratingText, "4.9")
        XCTAssertEqual(courier.callURL?.absoluteString, "tel:+254712345678")
        XCTAssertEqual(KitoCourier(name: "Otieno").initials, "O")
        XCTAssertNil(KitoCourier(name: "Otieno").callURL)
    }

    func testSampleHistoryClearsFutureTimes() {
        let history = KitoOrderEvent.sampleHistory(upTo: .preparing, now: now)
        XCTAssertEqual(history.count, 5)
        XCTAssertNotNil(history[2].time)
        XCTAssertNil(history[3].time)
        XCTAssertNil(history[4].time)
    }

    func testSampleHistoryForCancelledEndsCancelled() {
        let history = KitoOrderEvent.sampleHistory(upTo: .cancelled, now: now)
        XCTAssertEqual(history.last?.stage, .cancelled)
    }

    func testStageSteps() {
        XCTAssertEqual(KitoOrderStage.happyPath.map(\.step), [0, 1, 2, 3, 4])
        XCTAssertEqual(KitoOrderStage.cancelled.step, -1)
    }

    func testSampleSignatureHasStrokesInsideUnitSquare() {
        let points = KitoDeliveryProof.sampleSignature.flatMap { $0 }
        XCTAssertFalse(points.isEmpty)
        XCTAssertTrue(points.allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) })
    }
}
