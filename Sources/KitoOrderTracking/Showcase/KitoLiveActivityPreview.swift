//
//  KitoLiveActivityPreview.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

#if canImport(ActivityKit)
import SwiftUI
import ActivityKit
import KitoCore

/// Which Live Activity surface `KitoLiveActivityPreview` draws.
public enum KitoLiveActivitySurface: String, Sendable, CaseIterable {
    case lockScreen
    case islandCompact
    case islandExpanded
    case islandMinimal

    public var label: String {
        switch self {
        case .lockScreen: return "Lock Screen"
        case .islandCompact: return "Compact"
        case .islandExpanded: return "Expanded"
        case .islandMinimal: return "Minimal"
        }
    }
}

/// The package's real Live Activity views, drawn inside the app in lifelike chrome — a Lock
/// Screen banner over a wallpaper, or the Dynamic Island's pill in each size. For design
/// reviews, onboarding ("here's what you'll see") and galleries; the system still draws the
/// real thing from your widget extension.
@available(iOS 16.1, *)
public struct KitoLiveActivityPreview: View {
    let merchantName: String
    let state: KitoOrderTrackingAttributes.ContentState
    let surface: KitoLiveActivitySurface
    let style: KitoOrderTrackingStyle

    public init(
        merchantName: String,
        update: KitoOrderUpdate,
        surface: KitoLiveActivitySurface = .lockScreen,
        style: KitoOrderTrackingStyle = .default
    ) {
        self.merchantName = merchantName
        self.state = KitoOrderTrackingAttributes.ContentState(from: update)
        self.surface = surface
        self.style = style
    }

    public var body: some View {
        Group {
            switch surface {
            case .lockScreen: lockScreen
            case .islandCompact: island { compact }
            case .islandExpanded: island { expanded }
            case .islandMinimal: island { minimal }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(surface.label) preview: \(state.headline)")
    }

    private var lockScreen: some View {
        VStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(Date(), format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.subheadline.weight(.semibold))
                Text(Date(), format: .dateTime.hour().minute())
                    .font(.system(size: 64, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.92))
            .padding(.top, 18)

            KitoOrderLockScreenView(merchantName: merchantName, state: state, style: style)
                .environment(\.colorScheme, .dark)
                .foregroundStyle(.white)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.2, blue: 0.42), Color(red: 0.42, green: 0.2, blue: 0.5), Color(red: 0.95, green: 0.5, blue: 0.35)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 32, style: .continuous)
        )
        .environment(\.colorScheme, .dark)
    }

    private func island<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .environment(\.colorScheme, .dark)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                LinearGradient(colors: [Color(white: 0.16), Color(white: 0.06)], startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
    }

    private var compact: some View {
        HStack(spacing: 0) {
            KitoOrderIslandCompactLeadingView(state: state, style: style)
                .frame(width: 44)
            Spacer(minLength: 70)
            KitoOrderIslandCompactTrailingView(state: state)
                .frame(width: 52)
        }
        .frame(width: 236, height: 37)
        .background(Color.black, in: Capsule())
    }

    private var expanded: some View {
        KitoOrderIslandExpandedView(merchantName: merchantName, state: state, style: style)
            .frame(width: 340)
            .background(Color.black, in: RoundedRectangle(cornerRadius: 44, style: .continuous))
    }

    private var minimal: some View {
        HStack(spacing: 10) {
            Capsule().fill(Color.black).frame(width: 126, height: 37)
            KitoOrderIslandMinimalView(state: state, style: style)
                .frame(width: 37, height: 37)
                .background(Color.black, in: Circle())
        }
    }
}
#endif
