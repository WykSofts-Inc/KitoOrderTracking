# Live Activities

Show order progress on the Lock Screen and in the Dynamic Island.

## Overview

Apple requires the code that renders a Live Activity to live in a Widget
Extension target inside your app's Xcode project. A Swift package cannot create
that target, so KitoOrderTracking ships everything else: the
``KitoOrderTrackingAttributes`` data contract, the view model that requests and
updates the activity, and every view the extension renders.

If you skip the extension, `startTracking()` still works. The Live Activity
request fails silently and you get in-app tracking only, with no error shown to
the user.

### Add a Widget Extension

In Xcode, choose File > New > Target > Widget Extension and select
"Include Live Activity". Then add `KitoOrderTracking` to the extension target's
frameworks as well as the app target's. Both targets must use the same
``KitoOrderTrackingAttributes`` type, or ActivityKit cannot match them.

### Register the views

Replace Xcode's template widget with one that composes the package's views:

```swift
import WidgetKit
import SwiftUI
import KitoOrderTracking

struct OrderTrackingWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KitoOrderTrackingAttributes.self) { context in
            KitoOrderLockScreenView(
                merchantName: context.attributes.merchantName,
                state: context.state
            )
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    KitoOrderIslandExpandedView(
                        merchantName: context.attributes.merchantName,
                        state: context.state
                    )
                }
            } compactLeading: {
                KitoOrderIslandCompactLeadingView(state: context.state)
            } compactTrailing: {
                KitoOrderIslandCompactTrailingView(state: context.state)
            } minimal: {
                KitoOrderIslandMinimalView(state: context.state)
            }
        }
    }
}

@main
struct OrderTrackingWidgetBundle: WidgetBundle {
    var body: some Widget {
        OrderTrackingWidget()
    }
}
```

Pass your own ``KitoOrderTrackingStyle`` to the lock screen and island views to
match your branding.

### Start tracking

The app side is unchanged. ``KitoOrderTrackingScreen`` calls `startTracking()`
on appear, or you can call it yourself on a ``KitoOrderTrackingViewModel``.
Calling it again never starts a second Live Activity. Call `stopTracking()` to
end the activity early, for example when the user cancels the order.

### Receive push updates

By default the activity updates whenever the view model polls `fetchUpdate`.
To deliver updates the moment your backend knows about them, send each push
token from `pushTokenUpdates()` to your server, which then sends APNs
`liveactivity` pushes whose `content-state` mirrors the `Codable` keys of
``KitoOrderTrackingAttributes/ContentState``.

```swift
for await token in viewModel.pushTokenUpdates() {
    try? await YourBackend.registerLiveActivityPushToken(token, forOrder: order.id)
}
```

### Preview without a device

``KitoLiveActivityPreview`` draws the same Live Activity views inside your app,
for SwiftUI previews and onboarding screens, and ``KitoOrderTrackingSimulator``
drives a full order through every stage without a backend.
