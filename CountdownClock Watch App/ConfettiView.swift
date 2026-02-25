//
//  ConfettiView.swift
//  CountdownClock
//
//  Created by Laure Chipman on 1/2/26.
//


import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.x, y: particle.y)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
            }
        }
        // Fill the tile so .position() coordinates are meaningful
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            launchConfetti()
        }
    }

    private func launchConfetti() {
        // Fire an immediate burst and a follow-up burst 3 s later.
        // The follow-up is a safety net: the notification interface is
        // pre-rendered before it becomes visible, so the first burst might
        // start (and even finish) before the user ever sees the screen.
        // Having a second burst ensures at least one is seen.
        launchBurst()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            launchBurst()
        }
    }

    private func launchBurst() {
        // Delay particle creation by 0.4 s so they don't appear until the
        // notification view has had time to transition onto the screen.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            particles = (0..<20).map { _ in ConfettiParticle.random() }

            // Yield one render cycle so SwiftUI records the starting positions
            // before the animation begins — otherwise creation and movement are
            // batched into a single frame and nothing appears to move.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 2.0)) {
                    for index in particles.indices {
                        particles[index].y += 150
                        particles[index].rotation += Double.random(in: 90...360)
                        particles[index].opacity = 0
                    }
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable, Equatable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var rotation: Double
    var opacity: Double
    var color: Color

    static func == (lhs: ConfettiParticle, rhs: ConfettiParticle) -> Bool {
        // Compare all animating properties; exclude `id` so state changes are detected per particle
        lhs.x == rhs.x &&
        lhs.y == rhs.y &&
        lhs.size == rhs.size &&
        lhs.rotation == rhs.rotation &&
        lhs.opacity == rhs.opacity &&
        ConfettiParticle.colorsEqual(lhs.color, rhs.color)
    }

    private static func colorsEqual(_ a: Color, _ b: Color) -> Bool {
        #if canImport(UIKit)
        // Convert to UIColor and compare RGBA components
        let ua = UIColor(a)
        let ub = UIColor(b)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        ua.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        ub.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return ar == br && ag == bg && ab == bb && aa == ba
        #elseif canImport(AppKit)
        let na = NSColor(a)
        let nb = NSColor(b)
        guard let ca = na.usingColorSpace(.deviceRGB), let cb = nb.usingColorSpace(.deviceRGB) else { return false }
        return ca.redComponent == cb.redComponent &&
               ca.greenComponent == cb.greenComponent &&
               ca.blueComponent == cb.blueComponent &&
               ca.alphaComponent == cb.alphaComponent
        #else
        // Fallback: assume equal only if description matches
        return String(describing: a) == String(describing: b)
        #endif
    }

    static func random() -> ConfettiParticle {
        ConfettiParticle(
            x: CGFloat.random(in: 0...160),
            y: CGFloat.random(in: 0...20),
            size: CGFloat.random(in: 4...10),
            rotation: Double.random(in: 0...360),
            opacity: 1,
            color: [.red, .yellow, .green, .blue, .orange, .pink].randomElement()!
        )
    }
}
