//
//  KitoOrderTrackingSimulator.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// Generates a realistic stage-by-stage sequence with timing, for demos,
/// SwiftUI Previews, and testing the Live Activity end-to-end without a real
/// backend. **Not for production** — a real app passes its own
/// `fetchUpdate` closure to `KitoOrderTrackingViewModel` backed by an actual
/// order API. This exists so "does the Dynamic Island actually update
/// correctly" is answerable in five minutes instead of needing a live order.
public struct KitoOrderTrackingSimulator: Sendable {
    public var merchantName: String
    public var courierName: String
    public var stageDuration: TimeInterval

    public init(merchantName: String = "Kito Kitchen", courierName: String = "Amara M.", stageDuration: TimeInterval = 8) {
        self.merchantName = merchantName
        self.courierName = courierName
        self.stageDuration = stageDuration
    }

    /// The full scripted sequence, in order. Feed these to a
    /// `KitoOrderTrackingViewModel`'s `fetchUpdate` closure via
    /// `nextUpdate()`, or just read the array directly for a Preview.
    public var script: [KitoOrderUpdate] {
        let eta = Date().addingTimeInterval(stageDuration * 4)
        return [
            KitoOrderUpdate(stage: .placed, detail: "We've received your order.", progress: 0.05),
            KitoOrderUpdate(stage: .confirmed, detail: "\(merchantName) confirmed your order.", progress: 0.25),
            KitoOrderUpdate(stage: .preparing, detail: "Your order is being prepared.", estimatedArrival: eta, progress: 0.5),
            KitoOrderUpdate(stage: .outForDelivery, detail: "\(courierName) is on the way.", estimatedArrival: eta, progress: 0.8, courierName: courierName),
            KitoOrderUpdate(stage: .delivered, detail: "Delivered — enjoy!", progress: 1.0, courierName: courierName),
        ]
    }

    /// A stateful cursor through `script`, advancing one stage every call —
    /// hand this directly to `KitoOrderTrackingViewModel`'s `fetchUpdate`:
    ///
    /// ```swift
    /// let simulator = KitoOrderTrackingSimulator()
    /// let viewModel = KitoOrderTrackingViewModel(
    ///     orderID: "demo-1", merchantName: simulator.merchantName,
    ///     initial: simulator.script[0], refreshInterval: simulator.stageDuration,
    ///     fetchUpdate: simulator.nextUpdate
    /// )
    /// ```
    public func makeCursor() -> @Sendable () async -> KitoOrderUpdate {
        let steps = script
        let box = CursorBox(steps: steps)
        return { await box.advance() }
    }

    /// Convenience matching `fetchUpdate: () async throws -> KitoOrderUpdate`.
    public var nextUpdate: @Sendable () async throws -> KitoOrderUpdate {
        let cursor = makeCursor()
        return { await cursor() }
    }
}

private actor CursorBox {
    private let steps: [KitoOrderUpdate]
    private var index = 0

    init(steps: [KitoOrderUpdate]) {
        self.steps = steps
    }

    func advance() -> KitoOrderUpdate {
        defer { index = min(index + 1, steps.count - 1) }
        return steps[index]
    }
}
