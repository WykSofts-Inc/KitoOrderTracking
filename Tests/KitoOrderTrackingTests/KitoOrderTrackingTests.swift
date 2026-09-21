//
//  KitoOrderTrackingTests.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoOrderTracking

final class KitoOrderTrackingTests: XCTestCase {
    func testStageOrderingIsSequential() {
        XCTAssertLessThan(KitoOrderStage.placed, .confirmed)
        XCTAssertLessThan(KitoOrderStage.confirmed, .preparing)
        XCTAssertLessThan(KitoOrderStage.preparing, .outForDelivery)
        XCTAssertLessThan(KitoOrderStage.outForDelivery, .delivered)
    }

    func testTerminalStages() {
        XCTAssertTrue(KitoOrderStage.delivered.isTerminal)
        XCTAssertTrue(KitoOrderStage.cancelled.isTerminal)
        XCTAssertFalse(KitoOrderStage.preparing.isTerminal)
    }

    func testOrderUpdateFillsDefaultHeadlineFromStage() {
        let update = KitoOrderUpdate(stage: .preparing)
        XCTAssertEqual(update.headline, "Preparing")
    }

    func testOrderUpdateExplicitHeadlineOverridesDefault() {
        let update = KitoOrderUpdate(stage: .preparing, headline: "Almost ready!")
        XCTAssertEqual(update.headline, "Almost ready!")
    }

    func testOrderUpdateDefaultProgressIncreasesWithStage() {
        let placed = KitoOrderUpdate(stage: .placed)
        let delivered = KitoOrderUpdate(stage: .delivered)
        XCTAssertLessThan(placed.progress, delivered.progress)
    }

    func testExplicitProgressOverridesDefault() {
        let update = KitoOrderUpdate(stage: .preparing, progress: 0.42)
        XCTAssertEqual(update.progress, 0.42)
    }

    func testStyleLabelFallsBackToStageDefault() {
        let style = KitoOrderTrackingStyle()
        XCTAssertEqual(style.label(for: .outForDelivery), "Out for delivery")
    }

    func testStyleLabelOverrideWins() {
        let style = KitoOrderTrackingStyle(stageLabels: [.outForDelivery: "On the way"])
        XCTAssertEqual(style.label(for: .outForDelivery), "On the way")
    }

    func testSimulatorScriptEndsAtDelivered() {
        let simulator = KitoOrderTrackingSimulator(stageDuration: 1)
        XCTAssertEqual(simulator.script.last?.stage, .delivered)
    }

    func testSimulatorScriptIsMonotonicallyProgressing() async {
        let simulator = KitoOrderTrackingSimulator(stageDuration: 1)
        let cursor = simulator.makeCursor()
        var previousProgress = -1.0
        for _ in simulator.script {
            let update = await cursor()
            XCTAssertGreaterThanOrEqual(update.progress, previousProgress)
            previousProgress = update.progress
        }
    }

    func testSimulatorCursorStopsAtLastStepOnceExhausted() async {
        let simulator = KitoOrderTrackingSimulator(stageDuration: 1)
        let cursor = simulator.makeCursor()
        for _ in 0..<(simulator.script.count + 5) {
            _ = await cursor()
        }
        let final = await cursor()
        XCTAssertEqual(final.stage, .delivered, "cursor should clamp at the final step, not crash on overrun")
    }
}
