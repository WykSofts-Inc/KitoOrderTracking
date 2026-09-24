//
//  KitoCourierCard.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// How much `KitoCourierCard` shows.
public enum KitoCourierCardStyle: String, Sendable, CaseIterable {
    /// Photo, name, rating, vehicle and plate, with round call and chat buttons.
    case card
    /// One row — photo, name, plate — with small buttons, for under a map.
    case compact
}

/// The courier: photo (or initials), rating, vehicle and number plate, with call and chat
/// buttons. Leave `onCall` out to call the courier's `phone` directly.
///
/// ```swift
/// KitoCourierCard(courier: courier, onChat: { showChat = true })
/// ```
public struct KitoCourierCard: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.openURL) private var openURL
    let courier: KitoCourier
    let style: KitoCourierCardStyle
    let onCall: (() -> Void)?
    let onChat: (() -> Void)?

    public init(courier: KitoCourier, style: KitoCourierCardStyle = .card, onCall: (() -> Void)? = nil, onChat: (() -> Void)? = nil) {
        self.courier = courier
        self.style = style
        self.onCall = onCall
        self.onChat = onChat
    }

    private var accent: Color { theme.colors.primary }

    public var body: some View {
        Group {
            switch style {
            case .card: card
            case .compact: compact
            }
        }
        .foregroundStyle(theme.colors.onBackground)
    }

    private var card: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                photo(size: 58)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your courier").font(.caption.weight(.semibold)).foregroundStyle(theme.colors.onBackground.opacity(0.5))
                    Text(courier.name).font(.headline)
                    HStack(spacing: 8) {
                        if let rating = courier.ratingText {
                            Label(rating, systemImage: "star.fill")
                                .labelStyle(KitoCompactLabelStyle())
                                .foregroundStyle(.orange)
                        }
                        if let deliveries = courier.deliveries {
                            Text("\(deliveries.formatted()) deliveries").foregroundStyle(theme.colors.onBackground.opacity(0.55))
                        }
                    }
                    .font(.caption.weight(.semibold))
                }
                Spacer()
            }
            HStack(spacing: 10) {
                vehicleBadge
                Spacer()
                actionButton("phone.fill", label: "Call \(courier.name)", filled: false, action: call)
                    .disabled(onCall == nil && courier.callURL == nil)
                actionButton("message.fill", label: "Message \(courier.name)", filled: true) { onChat?() }
                    .disabled(onChat == nil)
            }
        }
        .padding(16)
        .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(theme.colors.onBackground.opacity(0.06)))
    }

    private var compact: some View {
        HStack(spacing: 12) {
            photo(size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(courier.name).font(.subheadline.weight(.bold))
                HStack(spacing: 6) {
                    Image(systemName: courier.vehicle.systemImage)
                    if let plate = courier.plate { Text(plate).monospaced() }
                    if let rating = courier.ratingText {
                        Text("·")
                        Label(rating, systemImage: "star.fill").labelStyle(KitoCompactLabelStyle())
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.colors.onBackground.opacity(0.6))
            }
            Spacer()
            actionButton("phone.fill", label: "Call \(courier.name)", filled: false, size: 38, action: call)
                .disabled(onCall == nil && courier.callURL == nil)
            actionButton("message.fill", label: "Message \(courier.name)", filled: true, size: 38) { onChat?() }
                .disabled(onChat == nil)
        }
        .padding(10)
        .padding(.leading, 2)
        .background(.regularMaterial, in: Capsule())
    }

    private func photo(size: CGFloat) -> some View {
        ZStack {
            LinearGradient(colors: [accent.opacity(0.9), accent.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Text(courier.initials)
                .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            if let url = courier.photoURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image { image.resizable().scaledToFill() }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: courier.vehicle.systemImage)
                .font(.system(size: size * 0.18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size * 0.4, height: size * 0.4)
                .background(Color(white: 0.12), in: Circle())
                .overlay(Circle().stroke(theme.colors.surface, lineWidth: 2))
                .offset(x: 3, y: 3)
        }
        .accessibilityHidden(true)
    }

    private var vehicleBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: courier.vehicle.systemImage)
                .font(.system(size: 13, weight: .bold))
            VStack(alignment: .leading, spacing: 0) {
                Text(courier.vehicle.label).font(.caption2.weight(.semibold)).opacity(0.6)
                if let plate = courier.plate {
                    Text(plate).font(.caption.weight(.heavy)).monospaced()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(theme.colors.surfaceMuted, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func actionButton(_ symbol: String, label: String, filled: Bool, size: CGFloat = 46, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(filled ? theme.colors.onPrimary : theme.colors.onBackground)
                .frame(width: size, height: size)
                .background(filled ? accent : theme.colors.surfaceMuted, in: Circle())
        }
        .buttonStyle(KitoCourierPressStyle())
        .accessibilityLabel(label)
    }

    private func call() {
        if let onCall {
            onCall()
        } else if let url = courier.callURL {
            openURL(url)
        }
    }
}

struct KitoCompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon.font(.caption2)
            configuration.title
        }
    }
}

struct KitoCourierPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
