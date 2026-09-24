//
//  KitoOrderTrackingScreen.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// The full in-app tracking screen — timeline, ETA, courier row, all driven
/// by `viewModel.update`. Call `viewModel.startTracking()` in `.task` (or
/// let this view do it via `startsTrackingOnAppear`) and everything after
/// that is automatic.
///
/// Polling pauses when the screen goes away and picks up again when it comes
/// back, so a closed tracking screen doesn't keep calling your server. The
/// Live Activity keeps running — the Lock Screen is where people follow an
/// order once they leave the app. Pass `endsTrackingOnDisappear: true` to end
/// the Live Activity too.
public struct KitoOrderTrackingScreen: View {
    @Environment(\.kitoTheme) private var theme
    let viewModel: KitoOrderTrackingViewModel
    let style: KitoOrderTrackingStyle
    let startsTrackingOnAppear: Bool
    let endsTrackingOnDisappear: Bool

    @State private var pausedPolling = false

    public init(
        viewModel: KitoOrderTrackingViewModel,
        style: KitoOrderTrackingStyle = .default,
        startsTrackingOnAppear: Bool = true,
        endsTrackingOnDisappear: Bool = false
    ) {
        self.viewModel = viewModel
        self.style = style
        self.startsTrackingOnAppear = startsTrackingOnAppear
        self.endsTrackingOnDisappear = endsTrackingOnDisappear
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                header

                if style.showsETA, let eta = viewModel.update.estimatedArrival, !viewModel.update.stage.isTerminal {
                    etaRow(eta)
                }

                KitoOrderStageTimelineView(currentStage: viewModel.update.stage, style: style)
                    .padding(theme.spacing.lg)
                    .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: style.cornerRadius))

                if style.showsCourierRow, let courierName = viewModel.update.courierName {
                    courierRow(courierName)
                }

                if let detail = viewModel.update.detail {
                    Text(detail)
                        .font(style.detailFont)
                        .foregroundStyle(theme.colors.onBackground.opacity(0.7))
                }
            }
            .padding(theme.spacing.lg)
        }
        .refreshable { await viewModel.refreshNow() }
        .task {
            if startsTrackingOnAppear {
                viewModel.startTracking()
            } else if pausedPolling, !viewModel.update.stage.isTerminal {
                viewModel.startPolling()
            }
            pausedPolling = false
        }
        .onDisappear {
            if endsTrackingOnDisappear || viewModel.update.stage.isTerminal {
                viewModel.stopTracking()
            } else if viewModel.isPolling {
                viewModel.stopPolling()
                pausedPolling = true
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.merchantName)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onBackground.opacity(0.6))
                Text(viewModel.update.headline ?? viewModel.update.stage.defaultLabel)
                    .font(style.headlineFont)
                    .foregroundStyle(theme.colors.onBackground)
            }
            Spacer()
            if viewModel.isLiveActivityActive {
                Label("Live", systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption2.bold())
                    .foregroundStyle(theme.colors.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.colors.success.opacity(0.12), in: Capsule())
            }
        }
    }

    /// `Text(_:style:)` with `.relative` is a live-updating system text view
    /// (SwiftUI reschedules it itself) — "1 hr, 20 min", ticking down to
    /// "20 min," "5 min," and so on with no timer/state of our own to
    /// manage. The pulsing clock glyph is the one bit of animation this
    /// view adds explicitly.
    private func etaRow(_ eta: Date) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .symbolEffect(.pulse, options: .repeating)
            Text("Arriving in \(eta, style: .relative)")
        }
        .font(style.etaFont)
        .foregroundStyle(style.accentColor ?? theme.colors.primary)
    }

    private func courierRow(_ name: String) -> some View {
        HStack(spacing: theme.spacing.sm) {
            Circle()
                .fill(theme.colors.surfaceMuted)
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: "person.fill").foregroundStyle(theme.colors.onBackground.opacity(0.5)))
            Text(name)
                .font(style.detailFont.weight(.medium))
            Spacer()
        }
        .padding(theme.spacing.sm)
        .background(theme.colors.surfaceMuted, in: RoundedRectangle(cornerRadius: 12))
    }
}
