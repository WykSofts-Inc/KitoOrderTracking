//
//  KitoOrderLiveActivityViews.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

#if canImport(ActivityKit)
import SwiftUI
import ActivityKit
import KitoCore

/// The actual pixels shown on the Lock Screen and in the expanded Dynamic
/// Island. Your Widget Extension's `ActivityConfiguration` calls this —
/// see docs/INTEGRATION.md for the ~20 lines of extension-target glue that
/// wraps it. This type is deliberately dependency-light: it takes plain
/// values, not the ViewModel, because it runs in a **separate process**
/// (the widget extension) that never sees your app's `@Observable` graph.
@available(iOS 16.1, *)
public struct KitoOrderLockScreenView: View {
    let merchantName: String
    let state: KitoOrderTrackingAttributes.ContentState
    let style: KitoOrderTrackingStyle

    public init(merchantName: String, state: KitoOrderTrackingAttributes.ContentState, style: KitoOrderTrackingStyle = .default) {
        self.merchantName = merchantName
        self.state = state
        self.style = style
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: style.icon(for: state.stage))
                .font(.title2)
                .foregroundStyle(style.accentColor ?? .accentColor)
                .frame(width: 40, height: 40)
                .background((style.accentColor ?? .accentColor).opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(merchantName).font(.caption).foregroundStyle(.secondary)
                Text(state.headline).font(style.headlineFont.weight(.semibold))
                if let eta = state.estimatedArrival {
                    // Live-updating system text (SwiftUI reschedules this
                    // itself) — "1 hr, 20 min" ticking down with no push
                    // update or timer of our own needed.
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .symbolEffect(.pulse, options: .repeating)
                            .font(.caption2)
                        Text("Arriving in \(eta, style: .relative)")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(16)
    }
}

/// Dynamic Island's compact-leading region (the small icon shown when other
/// Live Activities/apps share the pill).
@available(iOS 16.1, *)
public struct KitoOrderIslandCompactLeadingView: View {
    let state: KitoOrderTrackingAttributes.ContentState
    let style: KitoOrderTrackingStyle

    public init(state: KitoOrderTrackingAttributes.ContentState, style: KitoOrderTrackingStyle = .default) {
        self.state = state
        self.style = style
    }

    public var body: some View {
        Image(systemName: style.icon(for: state.stage))
            .foregroundStyle(style.accentColor ?? .accentColor)
    }
}

/// Dynamic Island's compact-trailing region — kept to a few characters (ETA
/// minutes) since the OS gives this almost no horizontal room.
@available(iOS 16.1, *)
public struct KitoOrderIslandCompactTrailingView: View {
    let state: KitoOrderTrackingAttributes.ContentState

    public init(state: KitoOrderTrackingAttributes.ContentState) {
        self.state = state
    }

    public var body: some View {
        if let eta = state.estimatedArrival {
            Text(eta, style: .timer)
                .font(.caption2.monospacedDigit())
                .frame(width: 40)
        } else {
            Text("\(Int(state.progress * 100))%")
                .font(.caption2.monospacedDigit())
        }
    }
}

/// The minimal region — shown when multiple Live Activities compete for one
/// tiny dot of space. One glyph, nothing else.
@available(iOS 16.1, *)
public struct KitoOrderIslandMinimalView: View {
    let state: KitoOrderTrackingAttributes.ContentState
    let style: KitoOrderTrackingStyle

    public init(state: KitoOrderTrackingAttributes.ContentState, style: KitoOrderTrackingStyle = .default) {
        self.state = state
        self.style = style
    }

    public var body: some View {
        Image(systemName: style.icon(for: state.stage))
            .foregroundStyle(style.accentColor ?? .accentColor)
    }
}

/// The expanded Dynamic Island view — shown on long-press. Reuses the same
/// layout as the Lock Screen view since both have comparable space.
@available(iOS 16.1, *)
public struct KitoOrderIslandExpandedView: View {
    let merchantName: String
    let state: KitoOrderTrackingAttributes.ContentState
    let style: KitoOrderTrackingStyle

    public init(merchantName: String, state: KitoOrderTrackingAttributes.ContentState, style: KitoOrderTrackingStyle = .default) {
        self.merchantName = merchantName
        self.state = state
        self.style = style
    }

    public var body: some View {
        KitoOrderLockScreenView(merchantName: merchantName, state: state, style: style)
    }
}
#endif
