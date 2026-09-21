//
//  KitoOrderTrackingAttributes.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

#if canImport(ActivityKit)
import ActivityKit
import Foundation

/// The Live Activity data contract — this exact type must be imported by
/// BOTH your app target and your Widget Extension target (see
/// docs/INTEGRATION.md). `orderID`/`merchantName` are fixed for the
/// activity's lifetime (`ActivityAttributes`'s own properties); everything
/// that changes over time lives in `ContentState`.
@available(iOS 16.1, *)
public struct KitoOrderTrackingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var stage: KitoOrderStage
        public var headline: String
        public var detail: String?
        public var estimatedArrival: Date?
        public var progress: Double

        public init(from update: KitoOrderUpdate) {
            self.stage = update.stage
            self.headline = update.headline ?? update.stage.defaultLabel
            self.detail = update.detail
            self.estimatedArrival = update.estimatedArrival
            self.progress = update.progress
        }
    }

    public var orderID: String
    public var merchantName: String

    public init(orderID: String, merchantName: String) {
        self.orderID = orderID
        self.merchantName = merchantName
    }
}
#endif
