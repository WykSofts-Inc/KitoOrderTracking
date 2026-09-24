//
//  KitoOrderStatusViews.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

extension KitoOrderStage {
    /// Position in the happy path, 0...4; cancelled sits outside it.
    var step: Int {
        switch self {
        case .placed: return 0
        case .confirmed: return 1
        case .preparing: return 2
        case .outForDelivery: return 3
        case .delivered: return 4
        case .cancelled: return -1
        }
    }

    static let happyPath: [KitoOrderStage] = [.placed, .confirmed, .preparing, .outForDelivery, .delivered]
}

/// How `KitoOrderStatusChip` is filled.
public enum KitoOrderChipStyle: String, Sendable, CaseIterable {
    case tinted
    case solid
    case outline
}

/// A compact status chip — "● Out for delivery" — for order lists and headers. In-progress
/// stages get a softly pulsing dot; delivered and cancelled get their own colours.
public struct KitoOrderStatusChip: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let stage: KitoOrderStage
    let style: KitoOrderChipStyle
    let trackingStyle: KitoOrderTrackingStyle

    @State private var pulsing = false

    public init(stage: KitoOrderStage, style: KitoOrderChipStyle = .tinted, trackingStyle: KitoOrderTrackingStyle = .default) {
        self.stage = stage
        self.style = style
        self.trackingStyle = trackingStyle
    }

    private var tint: Color {
        switch stage {
        case .delivered: return theme.colors.success
        case .cancelled: return theme.colors.danger
        case .placed, .confirmed: return trackingStyle.accentColor ?? theme.colors.primary
        case .preparing: return theme.colors.warning
        case .outForDelivery: return trackingStyle.accentColor ?? theme.colors.primary
        }
    }

    public var body: some View {
        HStack(spacing: 6) {
            if stage.isTerminal {
                Image(systemName: trackingStyle.icon(for: stage)).font(.caption2.weight(.bold))
            } else {
                ZStack {
                    Circle().fill(style == .solid ? .white : tint).frame(width: 7, height: 7)
                    Circle()
                        .stroke(style == .solid ? .white : tint, lineWidth: 1.5)
                        .frame(width: 7, height: 7)
                        .scaleEffect(pulsing ? 2.4 : 1)
                        .opacity(pulsing ? 0 : 0.8)
                }
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.easeOut(duration: 1.3).repeatForever(autoreverses: false)) { pulsing = true }
                }
            }
            Text(trackingStyle.label(for: stage)).font(.caption.weight(.bold))
        }
        .foregroundStyle(style == .solid ? .white : tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            switch style {
            case .tinted: Capsule().fill(tint.opacity(0.14))
            case .solid: Capsule().fill(tint)
            case .outline: Capsule().strokeBorder(tint.opacity(0.6), lineWidth: 1.2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status: \(trackingStyle.label(for: stage))")
    }
}

/// A horizontal track with the courier's vehicle riding along it and five stage dots — the
/// strip at the top of a delivery app's order screen. `progress` (0...1) moves the vehicle
/// smoothly between stages.
public struct KitoOrderProgressTrack: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let stage: KitoOrderStage
    let progress: Double
    let vehicle: KitoCourierVehicle
    let style: KitoOrderTrackingStyle

    public init(stage: KitoOrderStage, progress: Double? = nil, vehicle: KitoCourierVehicle = .motorbike, style: KitoOrderTrackingStyle = .default) {
        self.stage = stage
        self.progress = min(max(progress ?? KitoOrderUpdate(stage: stage).progress, 0), 1)
        self.vehicle = vehicle
        self.style = style
    }

    private var accent: Color { stage == .cancelled ? theme.colors.danger : (style.accentColor ?? theme.colors.primary) }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let fill = CGFloat(stage == .cancelled ? 0 : progress)
                ZStack(alignment: .leading) {
                    Capsule().fill(theme.colors.onBackground.opacity(0.08)).frame(height: 6)
                    Capsule()
                        .fill(LinearGradient(colors: [accent.opacity(0.5), accent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(6, width * fill), height: 6)
                    ForEach(Array(KitoOrderStage.happyPath.enumerated()), id: \.offset) { index, dotStage in
                        let x = width * CGFloat(index) / CGFloat(KitoOrderStage.happyPath.count - 1)
                        Circle()
                            .fill(stage.step >= dotStage.step && stage != .cancelled ? accent : theme.colors.surfaceMuted)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(theme.colors.background, lineWidth: 2))
                            .offset(x: min(max(x - 5, 0), width - 10))
                    }
                    Image(systemName: stage == .delivered ? "checkmark" : vehicle.systemImage)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(accent, in: Circle())
                        .shadow(color: accent.opacity(0.45), radius: 8, y: 3)
                        .contentTransition(.symbolEffect(.replace))
                        .offset(x: min(max(width * fill - 16, 0), width - 32))
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 34)
            HStack {
                Text(style.label(for: .placed))
                Spacer()
                Text(style.label(for: .delivered))
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(theme.colors.onBackground.opacity(0.5))
        }
        .animation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.8), value: progress)
        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8), value: stage)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(style.label(for: stage))
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

/// A detailed history timeline: each event with its time and place, the current one pulsing,
/// the line between them filling as the order moves. Future stages are shown dimmed.
public struct KitoOrderEventTimeline: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let events: [KitoOrderEvent]
    let currentStage: KitoOrderStage
    let style: KitoOrderTrackingStyle

    @State private var pulsing = false

    public init(events: [KitoOrderEvent], currentStage: KitoOrderStage, style: KitoOrderTrackingStyle = .default) {
        self.events = events
        self.currentStage = currentStage
        self.style = style
    }

    private var accent: Color { currentStage == .cancelled ? theme.colors.danger : (style.accentColor ?? theme.colors.primary) }

    private func isDone(_ event: KitoOrderEvent) -> Bool {
        if currentStage == .cancelled { return event.stage == .cancelled || event.time != nil }
        return event.stage.step <= currentStage.step
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                let done = isDone(event)
                let current = event.stage == currentStage
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        ZStack {
                            if current && !currentStage.isTerminal {
                                Circle()
                                    .fill(accent.opacity(0.25))
                                    .frame(width: 34, height: 34)
                                    .scaleEffect(pulsing ? 1.25 : 0.85)
                                    .opacity(pulsing ? 0 : 1)
                            }
                            Circle()
                                .fill(done ? accent : theme.colors.surfaceMuted)
                                .frame(width: 28, height: 28)
                            Image(systemName: done && !current ? "checkmark" : style.icon(for: event.stage))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(done ? Color.white : theme.colors.onBackground.opacity(0.35))
                        }
                        .frame(width: 34, height: 34)
                        if index < events.count - 1 {
                            ZStack(alignment: .top) {
                                Capsule().fill(theme.colors.onBackground.opacity(0.08))
                                Capsule()
                                    .fill(accent)
                                    .scaleEffect(x: 1, y: isDone(events[index + 1]) ? 1 : 0, anchor: .top)
                            }
                            .frame(width: 3)
                            .frame(minHeight: 30)
                            .padding(.vertical, 2)
                        }
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(event.title)
                                .font(current ? .subheadline.weight(.heavy) : .subheadline.weight(.semibold))
                            Spacer()
                            if let time = event.time {
                                Text(time, format: .dateTime.hour().minute())
                                    .font(.caption.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(theme.colors.onBackground.opacity(0.5))
                            }
                        }
                        if let detail = event.detail {
                            Text(detail).font(.caption).foregroundStyle(theme.colors.onBackground.opacity(0.6))
                        }
                        if let location = event.location {
                            Label(location, systemImage: "mappin.and.ellipse")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(theme.colors.onBackground.opacity(0.5))
                        }
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 14)
                    .opacity(done ? 1 : 0.45)
                }
                .accessibilityElement(children: .combine)
                .accessibilityValue(current ? "Current" : (done ? "Done" : "Upcoming"))
            }
        }
        .foregroundStyle(theme.colors.onBackground)
        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.82), value: currentStage)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { pulsing = true }
        }
    }
}

public extension KitoOrderEvent {
    /// A plausible history for `stage`, timed backwards from `now` — for previews and demos.
    static func sampleHistory(upTo stage: KitoOrderStage, merchant: String = "Mama Akinyi's Kitchen", courier: String = "Amara", now: Date = Date()) -> [KitoOrderEvent] {
        let base = now.addingTimeInterval(-26 * 60)
        let all: [KitoOrderEvent] = [
            KitoOrderEvent(stage: .placed, detail: "Order #KE-2048 · 3 items", time: base, location: "Kilimani, Nairobi"),
            KitoOrderEvent(stage: .confirmed, detail: "\(merchant) accepted your order", time: base.addingTimeInterval(2 * 60)),
            KitoOrderEvent(stage: .preparing, detail: "Fish and ugali on the fire", time: base.addingTimeInterval(5 * 60), location: "\(merchant), Marcus Garvey Rd"),
            KitoOrderEvent(stage: .outForDelivery, detail: "\(courier) picked up your order", time: base.addingTimeInterval(19 * 60), location: "Argwings Kodhek Rd"),
            KitoOrderEvent(stage: .delivered, detail: "Handed to Wycliff N", time: base.addingTimeInterval(26 * 60), location: "Home"),
        ]
        guard stage != .cancelled else {
            return Array(all.prefix(2)) + [KitoOrderEvent(stage: .cancelled, detail: "Refund of KES 1,450 on its way to M-Pesa", time: base.addingTimeInterval(4 * 60))]
        }
        return all.map { event in
            var copy = event
            if event.stage.step > stage.step { copy.time = nil }
            return copy
        }
    }
}
