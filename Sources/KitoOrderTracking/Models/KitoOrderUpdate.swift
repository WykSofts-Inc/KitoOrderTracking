//
//  KitoOrderUpdate.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// One snapshot of an order's state. **This is the one type you produce from
/// real data** — everything else in the package (screen, widget, Live
/// Activity) renders from this struct. Nothing in KitoOrderTracking calls a
/// network API itself; you supply updates via a closure (see
/// `KitoOrderTrackingViewModel`).
public struct KitoOrderUpdate: Codable, Hashable, Sendable {
    public var stage: KitoOrderStage
    public var headline: String?
    public var detail: String?
    public var estimatedArrival: Date?
    /// 0...1, independent of `stage` so you can show intra-stage progress
    /// (e.g. "60% through preparing") rather than only five discrete jumps.
    public var progress: Double
    public var courierName: String?
    public var courierPhotoURL: URL?

    public init(
        stage: KitoOrderStage,
        headline: String? = nil,
        detail: String? = nil,
        estimatedArrival: Date? = nil,
        progress: Double? = nil,
        courierName: String? = nil,
        courierPhotoURL: URL? = nil
    ) {
        self.stage = stage
        self.headline = headline ?? stage.defaultLabel
        self.detail = detail
        self.estimatedArrival = estimatedArrival
        // Falls back to the stage's position in the sequence so a caller who
        // doesn't track fine-grained progress still gets a sensible timeline fill.
        self.progress = progress ?? KitoOrderUpdate.defaultProgress(for: stage)
        self.courierName = courierName
        self.courierPhotoURL = courierPhotoURL
    }

    private static func defaultProgress(for stage: KitoOrderStage) -> Double {
        switch stage {
        case .placed: return 0.05
        case .confirmed: return 0.25
        case .preparing: return 0.5
        case .outForDelivery: return 0.8
        case .delivered: return 1.0
        case .cancelled: return 0.0
        }
    }
}
