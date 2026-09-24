# ``KitoOrderTracking``

An order-tracking screen, a self-refreshing view model, and Live Activity support, styled from one struct.

## Overview

KitoOrderTracking renders a complete delivery-tracking experience from a single
value type, ``KitoOrderUpdate``. Nothing in the package calls a network API: you
supply updates through a `fetchUpdate` closure, and the screen, the stage
timeline, and the Live Activity all render from whatever update you return.

``KitoOrderTrackingViewModel`` polls `fetchUpdate` on the interval you choose
and starts a Live Activity when the user has them enabled. It stops on its own
once the order reaches a terminal stage (`.delivered` or `.cancelled`), and
``KitoOrderTrackingScreen`` pauses polling while it is off screen and supports
pull-to-refresh with no extra code.

```swift
import SwiftUI
import KitoOrderTracking

struct OrderScreen: View {
    @State private var viewModel: KitoOrderTrackingViewModel

    init(order: Order) {
        _viewModel = State(initialValue: KitoOrderTrackingViewModel(
            orderID: order.id,
            merchantName: order.merchantName,
            initial: order.lastKnownUpdate,
            refreshInterval: 15,
            fetchUpdate: { try await OrdersAPI.fetchStatus(order.id) }
        ))
    }

    var body: some View {
        KitoOrderTrackingScreen(viewModel: viewModel)
    }
}
```

``KitoOrderTrackingStyle`` customizes the accent color, fonts, per-stage labels
and icons, timeline layout, and corner radius; every field has a default that
follows the KitoCore theme. ``KitoOrderTrackingSimulator`` scripts a realistic
sequence of updates, so you can demo the whole flow, including the Dynamic
Island, before any order API exists.

Showing a Live Activity also requires a small Widget Extension target in your
Xcode project. See <doc:LiveActivities>.

## Topics

### Essentials

- <doc:LiveActivities>
- ``KitoOrderTrackingViewModel``
- ``KitoOrderTrackingScreen``

### Order Data

- ``KitoOrderUpdate``
- ``KitoOrderStage``
- ``KitoOrderEvent``
- ``KitoCourier``
- ``KitoCourierVehicle``
- ``KitoDeliveryProof``
- ``KitoETA``

### Styling

- ``KitoOrderTrackingStyle``
- ``KitoOrderTimelineLayout``

### Tracking Components

- ``KitoOrderStageTimelineView``
- ``KitoOrderStatusChip``
- ``KitoOrderChipStyle``
- ``KitoOrderProgressTrack``
- ``KitoOrderEventTimeline``
- ``KitoCourierCard``
- ``KitoCourierCardStyle``
- ``KitoETACountdown``
- ``KitoETACountdownStyle``
- ``KitoDeliveryProofView``
- ``KitoDeliverySignaturePad``
- ``KitoDeliverySignatureShape``

### Live Activities

- ``KitoOrderTrackingAttributes``
- ``KitoOrderLockScreenView``
- ``KitoOrderIslandExpandedView``
- ``KitoOrderIslandCompactLeadingView``
- ``KitoOrderIslandCompactTrailingView``
- ``KitoOrderIslandMinimalView``
- ``KitoLiveActivityPreview``
- ``KitoLiveActivitySurface``

### Simulation and Notifications

- ``KitoOrderTrackingSimulator``
- ``KitoOrderNotificationScheduler``
