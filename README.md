# KitoOrderTracking

**[Documentation](https://wyksofts-inc.github.io/KitoOrderTracking/documentation/kitoordertracking/)**

_Wycliff · wyksoftsinc.com · 9/21/26_

A full order-tracking screen, a self-refreshing MVVM data layer, and Live
Activity support — the Dynamic Island / Lock Screen "notch" presentation —
all themeable via one style struct.

**Read [docs/INTEGRATION.md](docs/INTEGRATION.md) before you expect the
Dynamic Island to actually show anything** — it requires ~20 lines of glue
in a Widget Extension target that only Xcode (not SPM) can create. Everything
else on this page works without that extension.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoOrderTracking.git", from: "1.2.0"),
```

## The one type you produce from real data: `KitoOrderUpdate`

Nothing in this package calls a network API. You supply updates via a
closure; everything else — the screen, the timeline, the Live Activity —
renders from whatever `KitoOrderUpdate` you hand it.

```swift
let update = KitoOrderUpdate(
    stage: .outForDelivery,
    headline: "On the way",
    detail: "Amara is 4 minutes away",
    estimatedArrival: Date().addingTimeInterval(4 * 60),
    courierName: "Amara M."
)
```

## Sample 1 — Minimal, self-refreshing tracking screen

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
            refreshInterval: 15,                     // <- you choose the cadence
            fetchUpdate: { try await OrdersAPI.fetchStatus(order.id) }
        ))
    }

    var body: some View {
        KitoOrderTrackingScreen(viewModel: viewModel)
    }
}
```

`startTracking()` is called automatically on appear; it begins polling
`fetchUpdate` on your interval AND starts a Live Activity if the user has
them enabled (silently skipped otherwise — never an error).

## Sample 2 — Full styling: fonts, colors, labels, layout

```swift
let style = KitoOrderTrackingStyle(
    accentColor: .orange,
    headlineFont: .system(size: 22, weight: .heavy, design: .rounded),
    detailFont: .system(size: 14, weight: .medium),
    stageLabels: [
        .outForDelivery: "Rider is on the way",
        .delivered: "Enjoy your meal!",
    ],
    stageIcons: [
        .outForDelivery: "scooter",
    ],
    showsCourierRow: true,
    showsETA: true,
    timelineLayout: .vertical,
    cornerRadius: 28
)

KitoOrderTrackingScreen(viewModel: viewModel, style: style)
```

Every one of those fields is optional — pass nothing and you get sensible
defaults matching your `KitoTheme`.

## Sample 3 — Compact timeline for a small card, not a full screen

```swift
KitoOrderStageTimelineView(currentStage: update.stage, style: KitoOrderTrackingStyle(timelineLayout: .compact))
    .frame(height: 4)
```

## Sample 4 — Simulating the whole flow end-to-end (no backend needed)

```swift
let simulator = KitoOrderTrackingSimulator(merchantName: "Kito Kitchen", stageDuration: 6)

let viewModel = KitoOrderTrackingViewModel(
    orderID: "demo-1",
    merchantName: simulator.merchantName,
    initial: simulator.script[0],
    refreshInterval: simulator.stageDuration,
    fetchUpdate: simulator.nextUpdate
)

KitoOrderTrackingScreen(viewModel: viewModel)
```

Watch the Dynamic Island update every `stageDuration` seconds, straight
through to "Delivered" — useful for demoing the feature before any real
order API exists, and for SwiftUI Previews:

```swift
#Preview {
    let simulator = KitoOrderTrackingSimulator()
    KitoOrderTrackingScreen(viewModel: KitoOrderTrackingViewModel(
        orderID: "preview", merchantName: simulator.merchantName,
        initial: simulator.script[2], refreshInterval: 999,
        fetchUpdate: simulator.nextUpdate
    ))
}
```

## Sample 5 — Manual refresh (pull-to-refresh is already wired in)

```swift
Button("Refresh now") {
    Task { await viewModel.refreshNow() }
}
```

`KitoOrderTrackingScreen` already has `.refreshable { await viewModel.refreshNow() }`
built in — pull-to-refresh works with no extra code.

## Sample 6 — Local notifications alongside the Live Activity

```swift
let scheduler = KitoOrderNotificationScheduler()

// After a stage change (e.g. inside your own fetchUpdate wrapper):
await scheduler.notify(merchantName: "Kito Kitchen", update: latestUpdate)
```

Requires notification permission already granted — request it once via
[KitoPermissions](https://github.com/WykSofts-Inc/KitoPermissions)'
`.notifications` case, not from inside this scheduler.

## Sample 7 — Ending tracking early (order cancelled by the user)

```swift
Button("Cancel order", role: .destructive) {
    viewModel.stopTracking()   // ends the Live Activity immediately
}
```

Tracking also stops itself automatically once a stage is terminal
(`.delivered` or `.cancelled`).

`KitoOrderTrackingScreen` pauses polling when it disappears and resumes when it
comes back, so a closed screen doesn't keep calling your server; the Live
Activity keeps running so the order can still be followed from the Lock
Screen. To end the Live Activity when the screen goes away as well:

```swift
KitoOrderTrackingScreen(viewModel: viewModel, endsTrackingOnDisappear: true)
```

Driving it yourself: `viewModel.stopPolling()` / `startPolling()` pause and
resume polling without touching the Live Activity, and `isPolling` says
whether it's running. Calling `startTracking()` again never starts a second
Live Activity.

## Sample 8 — Real push updates instead of polling

See [docs/INTEGRATION.md](docs/INTEGRATION.md#real-push-updates-optional-beyond-self-refresh)
for the full flow, including the exact APNs payload shape:

```swift
for await token in viewModel.pushTokenUpdates() {
    try? await YourBackend.registerLiveActivityPushToken(token, forOrder: order.id)
}
```

## Sample 9 — Reusing just the timeline in an order-history list

```swift
List(pastOrders) { order in
    VStack(alignment: .leading) {
        Text(order.merchantName)
        KitoOrderStageTimelineView(currentStage: order.finalStage, style: .init(timelineLayout: .compact))
    }
}
```

## Showcase components (1.1)

```swift
// Status chips for order lists
KitoOrderStatusChip(stage: .outForDelivery)                 // pulsing dot, tinted
KitoOrderStatusChip(stage: .delivered, style: .solid)

// A track with the courier's vehicle riding along it
KitoOrderProgressTrack(stage: update.stage, progress: update.progress, vehicle: .motorbike)

// A detailed history with times and places
KitoOrderEventTimeline(events: events, currentStage: update.stage)

// The courier, with call and chat
KitoCourierCard(
    courier: KitoCourier(name: "Amara Mwangi", phone: "+254712345678", vehicle: .motorbike, plate: "KMFB 214C", rating: 4.9),
    onChat: { showChat = true }
)

// A live ETA that ticks on its own
KitoETACountdown(eta: eta, start: pickedUpAt, style: .ring)   // .digital, .pill, .headline
// ...or with an arrival time that moves: read again on every tick
KitoETACountdown(style: .ring, eta: { now in order.eta(at: now) }, start: { _ in order.pickedUpAt })

// Proof of delivery, and a pad to capture the signature
KitoDeliveryProofView(proof: KitoDeliveryProof(recipientName: "Wycliff N", deliveredAt: .now, code: "4821"))
KitoDeliverySignaturePad(strokes: $strokes)

// The real Live Activity views drawn in-app, for previews and onboarding
KitoLiveActivityPreview(merchantName: "Mama Akinyi's Kitchen", update: update, surface: .islandExpanded)
```

`KitoETA` holds the countdown maths (`clock`, `minutesText`, `elapsedFraction`) if you
want your own presentation. Every animation respects Reduce Motion. The Live Activity
attributes and widget views are unchanged, so existing widget extensions keep working.

## Migrating from 1.1

The proof-of-delivery signature types are renamed so they don't clash with
[KitoSignature](https://github.com/WykSofts-Inc/KitoSignature), which owns `KitoSignaturePad`:

| 1.1 | 1.2 |
| --- | --- |
| `KitoSignaturePad` | `KitoDeliverySignaturePad` |
| `KitoSignatureShape` | `KitoDeliverySignatureShape` |

Parameters are unchanged. `KitoOrderTrackingScreen` now pauses polling whenever it
disappears (it used to keep polling until the order was delivered); the Live Activity
behaviour is unchanged unless you pass `endsTrackingOnDisappear: true`.

## What ships in this package vs. what you build

| Piece | Ships in KitoOrderTracking | You build |
| --- | --- | --- |
| Order data model, style config | ✅ | — |
| Self-refreshing ViewModel | ✅ | — |
| In-app tracking screen | ✅ | — |
| Live Activity attributes + views | ✅ | — |
| Widget Extension target registering them | — | ✅ (~20 lines, see INTEGRATION.md) |
| Real order data | — | ✅ (`fetchUpdate` closure) |
| APNs push server for real-time updates | — | ✅ (optional; polling works without it) |

## Right-to-left

- The timeline, status bar, courier card and Live Activity views mirror automatically in Arabic/Hebrew layouts; the vehicle symbols flip with them.
- Signatures are recorded from the physical touch point and drawn left-to-right, so the ink follows the finger and a signature is never shown mirrored.
- If you draw `KitoDeliverySignatureShape` yourself, add `.environment(\.layoutDirection, .leftToRight)` to it.
- The ETA countdown ring starts at the top in RTL too (mirrored).

## License

MIT
