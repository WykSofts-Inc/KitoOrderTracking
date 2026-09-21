//
//  KitoOrderNotificationScheduler.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import UserNotifications

/// Posts a local notification for a stage change — useful alongside (not
/// instead of) the Live Activity: some users keep the Island closed, and a
/// notification is what actually resurfaces "your order shipped" for them.
/// Requires `KitoPermissions`' `.notifications` permission to already be
/// granted; this type doesn't request it itself, since asking on every
/// stage change would be wrong — request once, elsewhere, at a sensible moment.
public struct KitoOrderNotificationScheduler: Sendable {
    public init() {}

    public func notify(merchantName: String, update: KitoOrderUpdate) async {
        let content = UNMutableNotificationContent()
        content.title = merchantName
        content.body = update.headline ?? update.stage.defaultLabel
        if let detail = update.detail { content.subtitle = detail }
        content.sound = update.stage.isTerminal ? .default : nil

        let request = UNNotificationRequest(
            identifier: "kito.order.\(update.stage.rawValue).\(UUID().uuidString)",
            content: content,
            trigger: nil // fires immediately — this call already happened on a refresh/stage change
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}
