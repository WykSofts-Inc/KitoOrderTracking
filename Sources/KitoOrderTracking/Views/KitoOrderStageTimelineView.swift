//
//  KitoOrderStageTimelineView.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// The stage timeline — four layouts (`KitoOrderTrackingStyle.timelineLayout`)
/// for the in-progress stages, plus dedicated terminal rows for `.delivered`
/// and `.cancelled` that always take over regardless of layout: a single
/// order either ended well or didn't, and both deserve their own clear
/// moment rather than being buried as just the last step in a list.
/// Reusable on its own if you want the timeline without the rest of
/// `KitoOrderTrackingScreen`'s chrome.
public struct KitoOrderStageTimelineView: View {
    @Environment(\.kitoTheme) private var theme
    let currentStage: KitoOrderStage
    let style: KitoOrderTrackingStyle

    private static let sequence: [KitoOrderStage] = [.placed, .confirmed, .preparing, .outForDelivery, .delivered]
    private static let inProgressSequence: [KitoOrderStage] = [.placed, .confirmed, .preparing, .outForDelivery]

    public init(currentStage: KitoOrderStage, style: KitoOrderTrackingStyle = .default) {
        self.currentStage = currentStage
        self.style = style
    }

    public var body: some View {
        switch currentStage {
        case .cancelled:
            terminalRow(icon: style.icon(for: .cancelled), label: style.label(for: .cancelled), color: theme.colors.danger)
        case .delivered:
            terminalRow(icon: style.icon(for: .delivered), label: style.label(for: .delivered), color: theme.colors.success)
        default:
            switch style.timelineLayout {
            case .vertical: verticalTimeline(showsNumbers: false)
            case .stepper: verticalTimeline(showsNumbers: true)
            case .horizontal: horizontalTimeline
            case .compact: compactRow
            }
        }
    }

    private func terminalRow(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            Text(label).font(style.headlineFont).foregroundStyle(color)
        }
        .padding(.vertical, theme.spacing.xs)
    }

    private func verticalTimeline(showsNumbers: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(Self.inProgressSequence.enumerated()), id: \.element) { index, stage in
                HStack(alignment: .top, spacing: theme.spacing.md) {
                    VStack(spacing: 0) {
                        stepCircle(for: stage, showsNumber: showsNumbers, index: index, size: 28)
                        if index < Self.inProgressSequence.count - 1 {
                            Rectangle()
                                .fill(isReached(Self.inProgressSequence[index + 1]) ? accentColor : theme.colors.surfaceMuted)
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

    private var horizontalTimeline: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(Self.inProgressSequence.enumerated()), id: \.element) { index, stage in
                VStack(spacing: 6) {
                    stepCircle(for: stage, showsNumber: false, index: index, size: 24)
                    Text(style.label(for: stage))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(isReached(stage) ? theme.colors.onBackground : theme.colors.onBackground.opacity(0.4))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)

                if index < Self.inProgressSequence.count - 1 {
                    Rectangle()
                        .fill(isReached(Self.inProgressSequence[index + 1]) ? accentColor : theme.colors.surfaceMuted)
                        .frame(height: 2)
                        .padding(.top, 11)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStage)
    }

    private var compactRow: some View {
        HStack(spacing: 6) {
            ForEach(Self.inProgressSequence, id: \.self) { stage in
                Capsule()
                    .fill(isReached(stage) ? accentColor : theme.colors.surfaceMuted)
                    .frame(height: 4)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStage)
    }

    @ViewBuilder
    private func stepCircle(for stage: KitoOrderStage, showsNumber: Bool, index: Int, size: CGFloat) -> some View {
        Circle()
            .fill(isReached(stage) ? accentColor : theme.colors.surfaceMuted)
            .frame(width: size, height: size)
            .overlay {
                if showsNumber {
                    Text("\(index + 1)")
                        .font(.system(size: size * 0.46, weight: .bold))
                        .foregroundStyle(isReached(stage) ? theme.colors.onPrimary : theme.colors.onBackground.opacity(0.4))
                } else {
                    Image(systemName: style.icon(for: stage))
                        .font(.system(size: size * 0.43, weight: .bold))
                        .foregroundStyle(isReached(stage) ? theme.colors.onPrimary : theme.colors.onBackground.opacity(0.4))
                }
            }
    }

    private func isReached(_ stage: KitoOrderStage) -> Bool {
        currentStage != .cancelled && currentStage >= stage
    }

    private var accentColor: Color {
        style.accentColor ?? theme.colors.primary
    }
}
