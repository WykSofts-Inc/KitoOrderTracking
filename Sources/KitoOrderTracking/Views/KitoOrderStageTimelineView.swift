//
//  KitoOrderStageTimelineView.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// The vertical stepper — one row per non-cancelled stage, filled up to the
/// current stage. Reusable on its own if you want the timeline without the
/// rest of `KitoOrderTrackingScreen`'s chrome.
public struct KitoOrderStageTimelineView: View {
    @Environment(\.kitoTheme) private var theme
    let currentStage: KitoOrderStage
    let style: KitoOrderTrackingStyle

    private static let sequence: [KitoOrderStage] = [.placed, .confirmed, .preparing, .outForDelivery, .delivered]

    public init(currentStage: KitoOrderStage, style: KitoOrderTrackingStyle = .default) {
        self.currentStage = currentStage
        self.style = style
    }

    public var body: some View {
        if currentStage == .cancelled {
            cancelledRow
        } else if style.compactTimeline {
            compactRow
        } else {
            fullTimeline
        }
    }

    private var fullTimeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(Self.sequence.enumerated()), id: \.element) { index, stage in
                HStack(alignment: .top, spacing: theme.spacing.md) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(isReached(stage) ? accentColor : theme.colors.surfaceMuted)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Image(systemName: style.icon(for: stage))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(isReached(stage) ? theme.colors.onPrimary : theme.colors.onBackground.opacity(0.4))
                            }
                        if index < Self.sequence.count - 1 {
                            Rectangle()
                                .fill(isReached(Self.sequence[index + 1]) ? accentColor : theme.colors.surfaceMuted)
                                .frame(width: 2)
                                .frame(minHeight: 24)
                        }
                    }
                    Text(style.label(for: stage))
                        .font(stage == currentStage ? style.headlineFont.weight(.semibold) : style.detailFont)
                        .foregroundStyle(isReached(stage) ? theme.colors.onBackground : theme.colors.onBackground.opacity(0.4))
                        .padding(.top, 4)
                    Spacer()
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStage)
    }

    private var compactRow: some View {
        HStack(spacing: 6) {
            ForEach(Self.sequence, id: \.self) { stage in
                Capsule()
                    .fill(isReached(stage) ? accentColor : theme.colors.surfaceMuted)
                    .frame(height: 4)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStage)
    }

    private var cancelledRow: some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: style.icon(for: .cancelled))
                .foregroundStyle(theme.colors.danger)
            Text(style.label(for: .cancelled))
                .font(style.headlineFont)
                .foregroundStyle(theme.colors.danger)
        }
    }

    private func isReached(_ stage: KitoOrderStage) -> Bool {
        currentStage != .cancelled && currentStage >= stage
    }

    private var accentColor: Color {
        style.accentColor ?? theme.colors.primary
    }
}
