//
//  KitoOrderTrackingViewModel.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation
import Observation
import KitoCore
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Owns one order's tracking lifecycle end to end: polls your data source on
/// the interval you give it, keeps a Dynamic Island / Lock Screen Live
/// Activity in sync with every update, and exposes the current state for
/// `KitoOrderTrackingScreen` to render. **You own the network call** — this
/// type never talks to a server itself, it calls the `fetchUpdate` closure
/// you pass in and renders whatever comes back.
@Observable
public final class KitoOrderTrackingViewModel: KitoViewModel {
    public private(set) var update: KitoOrderUpdate
    public var refreshInterval: TimeInterval
    public private(set) var isLiveActivityActive = false
    public private(set) var lastError: Error?

    public let orderID: String
    public let merchantName: String

    private let fetchUpdate: () async throws -> KitoOrderUpdate
    private var refreshTask: Task<Void, Never>?

    #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    private var typedActivity: Activity<KitoOrderTrackingAttributes>? {
        get { _activityBox as? Activity<KitoOrderTrackingAttributes> }
        set { _activityBox = newValue }
    }
    private var _activityBox: Any?
    #endif

    /// - Parameters:
    ///   - orderID: A stable identifier for this order — used as the Live
    ///     Activity's fixed attribute, not shown directly unless your style says to.
    ///   - refreshInterval: How often to call `fetchUpdate` automatically.
    ///     Pass whatever cadence fits your backend — Kito imposes no minimum.
    ///   - fetchUpdate: Your data source. Called on `startTracking()` and
    ///     every `refreshInterval` thereafter until `stopTracking()` or a
    ///     terminal stage (`.delivered`/`.cancelled`) is reached.
    public init(
        orderID: String,
        merchantName: String,
        initial: KitoOrderUpdate,
        refreshInterval: TimeInterval = 15,
        fetchUpdate: @escaping () async throws -> KitoOrderUpdate
    ) {
        self.orderID = orderID
        self.merchantName = merchantName
        self.update = initial
        self.refreshInterval = refreshInterval
        self.fetchUpdate = fetchUpdate
    }

    /// Starts the Live Activity (if the user has them enabled — silently
    /// skipped otherwise, never an error) and begins auto-refreshing.
    public func startTracking() {
        beginLiveActivity()
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refreshOnce()
                if self.update.stage.isTerminal { break }
                try? await Task.sleep(nanoseconds: UInt64(self.refreshInterval * 1_000_000_000))
            }
        }
    }

    public func stopTracking() {
        refreshTask?.cancel()
        refreshTask = nil
        Task { await endLiveActivity() }
    }

    /// Triggers one refresh immediately, outside the automatic interval —
    /// wire this to pull-to-refresh on `KitoOrderTrackingScreen`.
    public func refreshNow() async {
        await refreshOnce()
    }

    /// Sets the current update directly, bypassing `fetchUpdate` — for
    /// seeding state from a push notification payload your app already
    /// decoded, or for a UI that lets a user/tester jump straight to an
    /// arbitrary stage (a stage picker in a demo app, a QA scenario button)
    /// without waiting for the normal poll cadence. Still pushes the change
    /// to the Live Activity if one is active.
    public func setUpdate(_ update: KitoOrderUpdate) {
        self.update = update
        self.lastError = nil
        Task { await pushLiveActivityUpdate(update) }
    }

    private func refreshOnce() async {
        do {
            let latest = try await fetchUpdate()
            update = latest
            lastError = nil
            await pushLiveActivityUpdate(latest)
        } catch {
            // A failed refresh keeps showing the last known-good state rather
            // than blanking the screen — `lastError` is available for a
            // banner/toast, but the order timeline itself never goes empty
            // because one poll failed.
            lastError = error
        }
    }

    // MARK: - Live Activity lifecycle

    private func beginLiveActivity() {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            // User has Live Activities disabled system-wide, or for this app
            // specifically — fail open: tracking still works via the in-app
            // screen, we just skip the Island/Lock Screen surface.
            isLiveActivityActive = false
            return
        }
        let attributes = KitoOrderTrackingAttributes(orderID: orderID, merchantName: merchantName)
        let content = ActivityContent(state: KitoOrderTrackingAttributes.ContentState(from: update), staleDate: nil)
        do {
            let activity = try Activity.request(attributes: attributes, content: content)
            typedActivity = activity
            isLiveActivityActive = true
        } catch {
            lastError = error
            isLiveActivityActive = false
        }
        #endif
    }

    private func pushLiveActivityUpdate(_ update: KitoOrderUpdate) async {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *), let activity = typedActivity else { return }
        let content = ActivityContent(state: KitoOrderTrackingAttributes.ContentState(from: update), staleDate: nil)
        await activity.update(content)
        if update.stage.isTerminal {
            await activity.end(content, dismissalPolicy: .after(.now.addingTimeInterval(60)))
            typedActivity = nil
            isLiveActivityActive = false
        }
        #endif
    }

    private func endLiveActivity() async {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *), let activity = typedActivity else { return }
        let content = ActivityContent(state: KitoOrderTrackingAttributes.ContentState(from: update), staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
        typedActivity = nil
        isLiveActivityActive = false
        #endif
    }

    /// An `AsyncStream` of this Live Activity's push token, hex-encoded —
    /// hand each value to your backend so it can send real APNs updates
    /// (`content-state` pushes) instead of relying only on this device
    /// polling `fetchUpdate`. See docs/INTEGRATION.md for the APNs payload
    /// shape Apple expects. Building the actual push-sending server is
    /// outside what a client SDK can do — this is the client-side half of
    /// that wiring.
    #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    public func pushTokenUpdates() -> AsyncStream<String> {
        AsyncStream { continuation in
            guard let activity = typedActivity else {
                continuation.finish()
                return
            }
            let task = Task {
                for await tokenData in activity.pushTokenUpdates {
                    let hex = tokenData.map { String(format: "%02x", $0) }.joined()
                    continuation.yield(hex)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    #endif
}
