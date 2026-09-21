//
//  KitoOrderStage.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

/// The generic lifecycle every order-like flow moves through — food delivery,
/// package shipping, ride-hailing all fit this shape. `label`/`systemImage`
/// have sensible defaults but are fully overridable per stage via
/// `KitoOrderTrackingStyle.stageLabels`/`stageIcons`, so a courier app can
/// relabel `.outForDelivery` as "On the way" without a new enum case.
public enum KitoOrderStage: String, Codable, CaseIterable, Comparable, Sendable {
    case placed
    case confirmed
    case preparing
    case outForDelivery
    case delivered
    case cancelled

    public var defaultLabel: String {
        switch self {
        case .placed: return "Order placed"
        case .confirmed: return "Confirmed"
        case .preparing: return "Preparing"
        case .outForDelivery: return "Out for delivery"
        case .delivered: return "Delivered"
        case .cancelled: return "Cancelled"
        }
    }

    public var defaultSystemImage: String {
        switch self {
        case .placed: return "bag.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .preparing: return "flame.fill"
        case .outForDelivery: return "bicycle"
        case .delivered: return "house.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    /// Position in the normal (non-cancelled) flow, used to drive the
    /// timeline's fill progress. `.cancelled` sorts after everything since
    /// it's a terminal state reachable from any point, not a step in sequence.
    private var order: Int {
        switch self {
        case .placed: return 0
        case .confirmed: return 1
        case .preparing: return 2
        case .outForDelivery: return 3
        case .delivered: return 4
        case .cancelled: return 5
        }
    }

    public static func < (lhs: KitoOrderStage, rhs: KitoOrderStage) -> Bool {
        lhs.order < rhs.order
    }

    public var isTerminal: Bool {
        self == .delivered || self == .cancelled
    }
}
