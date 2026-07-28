// Pomodo/Views/TickBarView.swift
import SwiftUI

struct TickBarView: View {
    let elapsedFraction: Double
    private let tickCount = 60
    private let markerWidth: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Canvas { context, size in
                    let tickWidth: CGFloat = 1.5
                    let spacing = size.width / CGFloat(tickCount)
                    for index in 0..<tickCount {
                        let x = CGFloat(index) * spacing
                        let rect = CGRect(x: x, y: 0, width: tickWidth, height: size.height)
                        context.fill(Path(rect), with: .color(.gray.opacity(0.4)))
                    }
                }

                Rectangle()
                    .fill(Color.red)
                    .frame(width: markerWidth)
                    .offset(x: min(CGFloat(elapsedFraction) * geometry.size.width, geometry.size.width - markerWidth))
                    .animation(.linear(duration: 1), value: elapsedFraction)
            }
        }
        .frame(height: 24)
    }
}
