// Pomodo/Views/TickBarView.swift
import SwiftUI

struct TickBarView: View {
    let elapsedFraction: Double
    private let tickCount = 60

    var body: some View {
        Canvas { context, size in
            let tickWidth: CGFloat = 1.5
            let spacing = size.width / CGFloat(tickCount)
            for index in 0..<tickCount {
                let x = CGFloat(index) * spacing
                let rect = CGRect(x: x, y: 0, width: tickWidth, height: size.height)
                context.fill(Path(rect), with: .color(.gray.opacity(0.4)))
            }
            let markerX = CGFloat(elapsedFraction) * size.width
            let markerRect = CGRect(x: markerX, y: 0, width: 2, height: size.height)
            context.fill(Path(markerRect), with: .color(.red))
        }
        .frame(height: 24)
        .animation(.linear(duration: 1), value: elapsedFraction)
    }
}
