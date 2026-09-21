# Integration — the Widget Extension glue

**Read this before you expect a Live Activity to show up.** Apple requires
the code that renders a Dynamic Island / Lock Screen Live Activity to live
in a **Widget Extension target** inside your app's Xcode project. No Swift
Package can create that target for you — SPM ships libraries and
executables, not App Extension bundles. This is a platform constraint, not
a gap in this package.

What KitoOrderTracking *does* give you: everything except that one target.
The attributes type, the ViewModel that drives `Activity.request`/`.update`,
and every SwiftUI view the extension needs to render — you write ~20 lines
of glue, once, and it's done.

## Step 1 — Add a Widget Extension target

In Xcode: **File → New → Target → Widget Extension**. Name it something like
`OrderTrackingWidget`. When prompted, check **"Include Live Activity."**

## Step 2 — Add KitoOrderTracking to the extension target too

Your main app target already depends on `KitoOrderTracking` (for the screen
and ViewModel). The **extension target needs it as well** — both targets
must import the exact same `KitoOrderTrackingAttributes` type, or ActivityKit
can't match them up. In the target's "Frameworks and Libraries," add
`KitoOrderTracking`.

## Step 3 — Write the widget

In the extension target's Swift file (replacing the template Xcode
generated), the entire implementation is composing the views
KitoOrderTracking already gives you:

```swift
import WidgetKit
import SwiftUI
import KitoOrderTracking

struct OrderTrackingWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KitoOrderTrackingAttributes.self) { context in
            KitoOrderLockScreenView(
                merchantName: context.attributes.merchantName,
                state: context.state,
                style: .default   // pass your own KitoOrderTrackingStyle to match branding
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

That's the whole extension. Every visual piece — icons, layout, colors — is
defined once in KitoOrderTracking's `KitoOrderLiveActivityViews.swift` and
reused here; you are not re-implementing UI, just registering it with
`ActivityConfiguration`.

## Step 4 — Start tracking from your app

Nothing extension-specific here — this is the same `KitoOrderTrackingViewModel`
call whether or not you did steps 1–3. If you skip the extension entirely,
`startTracking()` still works — `beginLiveActivity()` fails open (see
`ENGINEERING_STANDARDS.md`'s "fail open" rule) and you simply get in-app
tracking with no Island/Lock Screen surface, no crash, no error the user sees.

```swift
let viewModel = KitoOrderTrackingViewModel(
    orderID: order.id,
    merchantName: "Kito Kitchen",
    initial: order.currentUpdate,
    refreshInterval: 15,
    fetchUpdate: { try await OrdersAPI.fetchStatus(order.id) }
)
viewModel.startTracking()
```

## Real push updates (optional, beyond self-refresh)

The default mechanism is **client-side polling** — `fetchUpdate` gets called
every `refreshInterval`. For "the update should arrive the instant the
kitchen marks it ready," not on the next poll, drive the Live Activity from
your backend via APNs instead:

```swift
if #available(iOS 16.1, *) {
    for await token in viewModel.pushTokenUpdates() {
        try? await YourBackend.registerLiveActivityPushToken(token, forOrder: order.id)
    }
}
```

Your backend then POSTs to Apple's APNs with `apns-push-type: liveactivity`
and a payload shaped like:

```json
{
  "aps": {
    "timestamp": 1732000000,
    "event": "update",
    "content-state": {
      "stage": "outForDelivery",
      "headline": "On the way",
      "detail": "Amara is 4 minutes away",
      "estimatedArrival": "2026-09-21T18:42:00Z",
      "progress": 0.8
    },
    "alert": {
      "title": "Order update",
      "body": "Your order is on the way"
    }
  }
}
```

`content-state`'s keys must match `KitoOrderTrackingAttributes.ContentState`'s
`Codable` keys exactly (they're the same property names, so this is a direct
mirror). Building and operating that APNs-sending server is your backend
team's work — it's outside what a client SDK can ship, since it requires
your Apple Push Notification service key and a server process.

## Testing without a real order API

Use `KitoOrderTrackingSimulator` — see the main README's samples. It scripts
a realistic five-stage sequence with timing, so you can see the Dynamic
Island update end-to-end in the simulator before any backend work exists.
