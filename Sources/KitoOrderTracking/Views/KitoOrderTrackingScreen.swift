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
public struct KitoOrderTrackingScreen: View {
    @Environment(\.kitoTheme) private var theme
    let viewModel: KitoOrderTrackingViewModel
    let style: KitoOrderTrackingStyle
    let startsTrackingOnAppear: Bool

    public init(
        viewModel: KitoOrderTrackingViewModel,
        style: KitoOrderTrackingStyle = .default,
        startsTrackingOnAppear: Bool = true
    ) {
        self.viewModel = viewModel
        self.style = style
        self.startsTrackingOnAppear = startsTrackingOnAppear
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
            if startsTrackingOnAppear { viewModel.startTracking() }
        }
        .onDisappear {
            if viewModel.update.stage.isTerminal { viewModel.stopTracking() }
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

    private func etaRow(_ eta: Date) -> some View {
        HStack {
            Image(systemName: "clock.fill")
            Text("Arriving by \(eta.formatted(date: .omitted, time: .shortened))")
                .font(style.etaFont)
        }
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
