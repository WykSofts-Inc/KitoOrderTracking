//
//  KitoOrderTrackingStyle.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// How the in-progress stages render. `.cancelled` and `.delivered` always
/// get their own dedicated terminal treatment (a single celebratory/warning
/// row) regardless of this setting — it only affects the four stages in
/// between.
public enum KitoOrderTimelineLayout: Sendable {
    /// Connected circles down the left, label to the right — the original default.
    case vertical
    /// Same steps, laid out left-to-right with labels below — fits a card better than a full screen.
    case horizontal
    /// A thin thermometer of capsules, no labels or icons — for a compact card or list row.
    case compact
    /// Vertical layout with numbered circles (1, 2, 3…) instead of stage icons.
    case stepper
}

/// Every customizable knob the screen, Live Activity, and widget views read.
/// Defaults derive from `KitoTheme`/`KitoChartTheme`-style conventions — pass
/// nothing and it matches the rest of your themed app; override individual
/// fields for order-tracking-specific branding (a courier brand color that
/// differs from your primary app color, for instance).
public struct KitoOrderTrackingStyle: Sendable {
    public var accentColor: Color?
    public var headlineFont: Font
    public var detailFont: Font
    public var etaFont: Font
    public var stageLabels: [KitoOrderStage: String]
    public var stageIcons: [KitoOrderStage: String]
    public var showsCourierRow: Bool
    public var showsETA: Bool
    public var timelineLayout: KitoOrderTimelineLayout
    public var cornerRadius: CGFloat

    public init(
        accentColor: Color? = nil,
        headlineFont: Font = .system(size: 20, weight: .bold),
        detailFont: Font = .system(size: 15, weight: .regular),
        etaFont: Font = .system(size: 15, weight: .semibold),
        stageLabels: [KitoOrderStage: String] = [:],
        stageIcons: [KitoOrderStage: String] = [:],
        showsCourierRow: Bool = true,
        showsETA: Bool = true,
        timelineLayout: KitoOrderTimelineLayout = .vertical,
        cornerRadius: CGFloat = 20
    ) {
        self.accentColor = accentColor
        self.headlineFont = headlineFont
        self.detailFont = detailFont
        self.etaFont = etaFont
        self.stageLabels = stageLabels
        self.stageIcons = stageIcons
        self.showsCourierRow = showsCourierRow
        self.showsETA = showsETA
        self.timelineLayout = timelineLayout
        self.cornerRadius = cornerRadius
    }

    public func label(for stage: KitoOrderStage) -> String {
        stageLabels[stage] ?? stage.defaultLabel
    }

    public func icon(for stage: KitoOrderStage) -> String {
        stageIcons[stage] ?? stage.defaultSystemImage
    }

    public static let `default` = KitoOrderTrackingStyle()
}
