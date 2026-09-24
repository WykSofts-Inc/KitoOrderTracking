//
//  KitoDeliveryProofView.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Draws signature strokes given in 0...1 unit coordinates, scaled to whatever frame it gets.
/// Animate `trim` to "write" the signature. Like any `Shape` it mirrors in right-to-left layouts,
/// so draw it inside `.environment(\.layoutDirection, .leftToRight)`, as the package's own views do.
public struct KitoDeliverySignatureShape: Shape {
    public var strokes: [[CGPoint]]

    public init(strokes: [[CGPoint]]) {
        self.strokes = strokes
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        for stroke in strokes where !stroke.isEmpty {
            let points = stroke.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) }
            path.move(to: points[0])
            if points.count == 1 {
                path.addLine(to: points[0])
                continue
            }
            for index in 1..<points.count {
                let mid = CGPoint(x: (points[index - 1].x + points[index].x) / 2, y: (points[index - 1].y + points[index].y) / 2)
                path.addQuadCurve(to: mid, control: points[index - 1])
            }
            path.addLine(to: points[points.count - 1])
        }
        return path
    }
}

/// A pad the recipient signs with a finger. Strokes are stored in unit coordinates so they
/// redraw at any size with `KitoDeliverySignatureShape`.
public struct KitoDeliverySignaturePad: View {
    @Environment(\.kitoTheme) private var theme
    @Binding var strokes: [[CGPoint]]
    let prompt: String

    public init(strokes: Binding<[[CGPoint]]>, prompt: String = "Sign here") {
        _strokes = strokes
        self.prompt = prompt
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(theme.colors.surface)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(theme.colors.onBackground.opacity(0.12), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                HStack(spacing: 6) {
                    Image(systemName: "xmark").font(.caption.weight(.bold))
                    Rectangle().fill(theme.colors.onBackground.opacity(0.2)).frame(height: 1)
                }
                .foregroundStyle(theme.colors.onBackground.opacity(0.35))
                .padding(.horizontal, 20)
                .padding(.bottom, proxy.size.height * 0.22)
                if strokes.isEmpty {
                    Text(prompt)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.colors.onBackground.opacity(0.35))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                }
                // Strokes are recorded from the physical touch location; a Shape would mirror them
                // in RTL, so draw the ink left-to-right.
                KitoDeliverySignatureShape(strokes: strokes)
                    .stroke(theme.colors.onBackground, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                    .environment(\.layoutDirection, .leftToRight)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let point = CGPoint(
                            x: min(max(value.location.x / max(proxy.size.width, 1), 0), 1),
                            y: min(max(value.location.y / max(proxy.size.height, 1), 0), 1)
                        )
                        if value.translation == .zero || strokes.isEmpty {
                            strokes.append([point])
                        } else {
                            strokes[strokes.count - 1].append(point)
                        }
                    }
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(strokes.isEmpty ? "Signature pad, empty" : "Signature pad, signed")
    }
}

/// Proof of delivery: the doorstep photo (or a placeholder), the recipient's signature
/// writing itself in, the handover code and time.
public struct KitoDeliveryProofView: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let proof: KitoDeliveryProof

    @State private var drawn: CGFloat = 0

    public init(proof: KitoDeliveryProof) {
        self.proof = proof
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(theme.colors.success)
                    .symbolEffect(.bounce, value: drawn > 0)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Delivered").font(.headline)
                    Text(proof.deliveredAt, format: .dateTime.weekday(.wide).hour().minute())
                        .font(.caption.weight(.medium))
                        .foregroundStyle(theme.colors.onBackground.opacity(0.55))
                }
                Spacer()
                if let code = proof.code {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Code").font(.caption2.weight(.semibold)).foregroundStyle(theme.colors.onBackground.opacity(0.5))
                        Text(code).font(.subheadline.weight(.heavy).monospaced())
                    }
                    .accessibilityElement(children: .combine)
                }
            }

            photo
                .frame(height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text("Signed by \(proof.recipientName)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.colors.onBackground.opacity(0.55))
                KitoDeliverySignatureShape(strokes: proof.signature.isEmpty ? KitoDeliveryProof.sampleSignature : proof.signature)
                    .trim(from: 0, to: drawn)
                    .stroke(theme.colors.onBackground, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .environment(\.layoutDirection, .leftToRight) // a signature is never mirrored
                    .frame(height: 70)
                    .padding(.horizontal, 8)
                    .background(alignment: .bottom) {
                        Rectangle().fill(theme.colors.onBackground.opacity(0.12)).frame(height: 1)
                    }
                    .accessibilityLabel("Signature of \(proof.recipientName)")
            }

            if let note = proof.note {
                Label(note, systemImage: "text.bubble")
                    .font(.caption)
                    .foregroundStyle(theme.colors.onBackground.opacity(0.65))
            }
        }
        .foregroundStyle(theme.colors.onBackground)
        .padding(16)
        .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onAppear {
            if reduceMotion {
                drawn = 1
            } else {
                drawn = 0
                withAnimation(.easeInOut(duration: 1.8).delay(0.3)) { drawn = 1 }
            }
        }
    }

    @ViewBuilder
    private var photo: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(red: 0.55, green: 0.42, blue: 0.3), Color(red: 0.3, green: 0.22, blue: 0.16)],
                startPoint: .top,
                endPoint: .bottom
            )
            // A stylised doorstep: door, mat and the parcel.
            VStack(spacing: 0) {
                Spacer()
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.82, green: 0.62, blue: 0.4))
                    .frame(width: 70, height: 48)
                    .overlay(Rectangle().fill(Color(red: 0.7, green: 0.5, blue: 0.3)).frame(width: 12))
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
                Capsule().fill(.black.opacity(0.25)).frame(width: 150, height: 14).padding(.top, 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 14)
            if let url = proof.photoURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image { image.resizable().scaledToFill() }
                }
            }
            Label("Left at the door", systemImage: "camera.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.4), in: Capsule())
                .padding(10)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Delivery photo")
    }
}
