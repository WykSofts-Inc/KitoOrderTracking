//
//  KitoETACountdown.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// How `KitoETACountdown` shows the time left.
public enum KitoETACountdownStyle: String, Sendable, CaseIterable {
    /// A ring that fills as the delivery gets closer, minutes in the middle.
    case ring
    /// Big ticking "12:05" digits.
    case digital
    /// A small "● 12 min" pill for headers and cards.
    case pill
    /// "Arriving in 12 min" with the arrival time underneath.
    case headline
}

/// A live ETA that ticks every second on its own. Pass `start` (when the order was placed or
/// picked up) so the ring knows how full to be.
///
/// ```swift
/// KitoETACountdown(eta: update.estimatedArrival!, start: pickedUpAt, style: .ring)
/// ```
///
/// When the arrival time itself moves — a courier who hasn't picked up yet, a demo clock, an ETA
/// your model recalculates — pass closures instead. They're read on every tick, so the countdown
/// stays current without anything else redrawing it:
///
/// ```swift
/// KitoETACountdown(style: .ring, eta: { now in order.eta(at: now) }, start: { _ in order.pickedUpAt })
/// ```
public struct KitoETACountdown: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let etaAt: (Date) -> Date
    let startAt: (Date) -> Date?
    let style: KitoETACountdownStyle
    let tint: Color?

    public init(eta: Date, start: Date? = nil, style: KitoETACountdownStyle = .ring, tint: Color? = nil) {
        self.init(style: style, tint: tint, eta: { _ in eta }, start: { _ in start })
    }

    /// A countdown whose arrival (and start) are worked out again on every tick from the current time.
    public init(style: KitoETACountdownStyle = .ring, tint: Color? = nil,
                eta: @escaping (Date) -> Date, start: @escaping (Date) -> Date? = { _ in nil }) {
        self.etaAt = eta
        self.startAt = start
        self.style = style
        self.tint = tint
    }

    private var accent: Color { tint ?? theme.colors.primary }

    public var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let eta = etaAt(now)
            let remaining = KitoETA.remaining(until: eta, now: now)
            Group {
                switch style {
                case .ring: ring(eta: eta, start: startAt(now), remaining: remaining, now: now)
                case .digital: digital(remaining: remaining)
                case .pill: pill(remaining: remaining)
                case .headline: headline(eta: eta, remaining: remaining)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(remaining < 30 ? "Arriving now" : "Arriving in \(KitoETA.minutesText(remaining))")
        }
    }

    private func ring(eta: Date, start: Date?, remaining: TimeInterval, now: Date) -> some View {
        let begin = start ?? eta.addingTimeInterval(-30 * 60)
        let fraction = KitoETA.elapsedFraction(start: begin, eta: eta, now: now)
        return ZStack {
            Circle().stroke(accent.opacity(0.14), lineWidth: 12)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(AngularGradient(colors: [accent.opacity(0.4), accent], center: .center, startAngle: .degrees(0), endAngle: .degrees(360 * max(fraction, 0.01))), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .flipsForRightToLeftLayoutDirection(true) // Circle doesn't mirror but rotation does; keeps the start at the top in RTL
                .animation(reduceMotion ? nil : .linear(duration: 1), value: fraction)
            VStack(spacing: 2) {
                Text(remaining < 30 ? "Now" : "\(Int((remaining / 60).rounded(.up)))")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(reduceMotion ? .identity : .numericText(countsDown: true))
                    .animation(.snappy, value: Int(remaining / 60))
                Text(remaining < 30 ? "arriving" : "min away")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.colors.onBackground.opacity(0.55))
                Text(eta, format: .dateTime.hour().minute())
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accent.opacity(0.14), in: Capsule())
                    .foregroundStyle(accent)
                    .padding(.top, 4)
            }
        }
        .frame(width: 170, height: 170)
        .foregroundStyle(theme.colors.onBackground)
    }

    private func digital(remaining: TimeInterval) -> some View {
        VStack(spacing: 6) {
            Text(KitoETA.clock(remaining))
                .font(.system(size: 54, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .contentTransition(reduceMotion ? .identity : .numericText(countsDown: true))
                .animation(.snappy, value: Int(remaining))
            Text("until your order arrives")
                .font(.footnote.weight(.medium))
                .foregroundStyle(theme.colors.onBackground.opacity(0.55))
        }
        .foregroundStyle(theme.colors.onBackground)
    }

    private func pill(remaining: TimeInterval) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill").symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
            Text(KitoETA.minutesText(remaining))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(accent.opacity(0.14), in: Capsule())
    }

    private func headline(eta: Date, remaining: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(remaining < 30 ? "Arriving now" : "Arriving in \(KitoETA.minutesText(remaining))")
                .font(.title2.weight(.heavy))
                .contentTransition(.numericText(countsDown: true))
                .animation(.snappy, value: Int(remaining / 60))
            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text("Estimated \(eta.formatted(date: .omitted, time: .shortened))")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(theme.colors.onBackground.opacity(0.6))
        }
        .foregroundStyle(theme.colors.onBackground)
    }
}
