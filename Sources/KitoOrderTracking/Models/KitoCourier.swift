//
//  KitoCourier.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation
import CoreGraphics

/// How the courier travels.
public enum KitoCourierVehicle: String, Codable, Sendable, CaseIterable {
    case motorbike
    case bicycle
    case car
    case van
    case onFoot

    public var systemImage: String {
        switch self {
        case .motorbike: return "scooter"
        case .bicycle: return "bicycle"
        case .car: return "car.fill"
        case .van: return "box.truck.fill"
        case .onFoot: return "figure.walk"
        }
    }

    public var label: String {
        switch self {
        case .motorbike: return "Motorbike"
        case .bicycle: return "Bicycle"
        case .car: return "Car"
        case .van: return "Van"
        case .onFoot: return "On foot"
        }
    }
}

/// The person bringing the order, for `KitoCourierCard`.
public struct KitoCourier: Codable, Hashable, Sendable {
    public var name: String
    public var phone: String?
    public var vehicle: KitoCourierVehicle
    /// Number plate, e.g. "KMFB 214C".
    public var plate: String?
    /// 0...5.
    public var rating: Double?
    public var deliveries: Int?
    public var photoURL: URL?

    public init(
        name: String,
        phone: String? = nil,
        vehicle: KitoCourierVehicle = .motorbike,
        plate: String? = nil,
        rating: Double? = nil,
        deliveries: Int? = nil,
        photoURL: URL? = nil
    ) {
        self.name = name
        self.phone = phone
        self.vehicle = vehicle
        self.plate = plate
        self.rating = rating
        self.deliveries = deliveries
        self.photoURL = photoURL
    }

    /// "AM" for "Amara Mwangi".
    public var initials: String {
        let words = name.split(whereSeparator: \.isWhitespace)
        let letters = [words.first?.first, words.count > 1 ? words.last?.first : nil].compactMap { $0 }
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    /// "4.9" — one decimal, or `nil` without a rating.
    public var ratingText: String? {
        rating.map { String(format: "%.1f", min(max($0, 0), 5)) }
    }

    /// A `tel:` link for the call button, digits and a leading + only.
    public var callURL: URL? {
        guard let phone else { return nil }
        let cleaned = phone.filter { $0.isNumber || $0 == "+" }
        return cleaned.isEmpty ? nil : URL(string: "tel:\(cleaned)")
    }
}

/// One entry in an order's history — what happened, when, and where.
public struct KitoOrderEvent: Identifiable, Hashable, Sendable {
    public var id: String { "\(stage.rawValue)-\(title)" }
    public var stage: KitoOrderStage
    public var title: String
    public var detail: String?
    public var time: Date?
    public var location: String?

    public init(stage: KitoOrderStage, title: String? = nil, detail: String? = nil, time: Date? = nil, location: String? = nil) {
        self.stage = stage
        self.title = title ?? stage.defaultLabel
        self.detail = detail
        self.time = time
        self.location = location
    }
}

/// Countdown maths for ETAs, kept pure so it's testable.
public enum KitoETA {
    /// Seconds left until `eta`, never negative.
    public static func remaining(until eta: Date, now: Date = Date()) -> TimeInterval {
        max(0, eta.timeIntervalSince(now))
    }

    /// "12:05" / "1:02:05" — a ticking countdown.
    public static func clock(_ remaining: TimeInterval) -> String {
        let total = Int(max(0, remaining).rounded(.up))
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        let seconds = total % 60
        return hours > 0 ? String(format: "%d:%02d:%02d", hours, minutes, seconds) : String(format: "%02d:%02d", minutes, seconds)
    }

    /// "Arriving now", "1 min", "12 min", "1 hr 5 min" — rounded up to whole minutes.
    public static func minutesText(_ remaining: TimeInterval) -> String {
        guard remaining >= 30 else { return "Arriving now" }
        let minutes = Int((remaining / 60).rounded(.up))
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let rest = minutes % 60
        return rest == 0 ? "\(hours) hr" : "\(hours) hr \(rest) min"
    }

    /// 0...1 of the way from `start` to `eta` — what a countdown ring fills to.
    public static func elapsedFraction(start: Date, eta: Date, now: Date = Date()) -> Double {
        let total = eta.timeIntervalSince(start)
        guard total > 0 else { return 1 }
        return min(max(now.timeIntervalSince(start) / total, 0), 1)
    }
}

/// What the courier captured at the door.
public struct KitoDeliveryProof: Equatable, Sendable {
    public var recipientName: String
    public var deliveredAt: Date
    public var photoURL: URL?
    /// Signature strokes in 0...1 unit coordinates (x right, y down), drawn by `KitoDeliverySignatureShape`.
    public var signature: [[CGPoint]]
    /// The one-time code the customer read out, if one was used.
    public var code: String?
    public var note: String?

    public init(recipientName: String, deliveredAt: Date, photoURL: URL? = nil, signature: [[CGPoint]] = [], code: String? = nil, note: String? = nil) {
        self.recipientName = recipientName
        self.deliveredAt = deliveredAt
        self.photoURL = photoURL
        self.signature = signature
        self.code = code
        self.note = note
    }

    /// A believable signature for previews and demos.
    public static let sampleSignature: [[CGPoint]] = {
        var first: [CGPoint] = []
        for step in 0...50 {
            let t = Double(step) / 50
            let wave: Double = sin(t * .pi * 3.2) * 0.22 * (1 - t * 0.4)
            first.append(CGPoint(x: 0.06 + t * 0.6, y: 0.55 - wave + t * 0.06))
        }
        var loop: [CGPoint] = []
        for step in 0...33 {
            let t = Double(step) / 33
            let angle: Double = t * .pi * 2
            loop.append(CGPoint(x: 0.62 + cos(angle) * 0.08 + t * 0.2, y: 0.5 + sin(angle) * 0.16))
        }
        let underline = [CGPoint(x: 0.1, y: 0.86), CGPoint(x: 0.5, y: 0.82), CGPoint(x: 0.92, y: 0.8)]
        return [first, loop, underline]
    }()
}
