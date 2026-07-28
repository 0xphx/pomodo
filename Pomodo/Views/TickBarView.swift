// Pomodo/Views/TickBarView.swift
import SwiftUI

struct TickBarView: View {
    let fraction: Double
    var isInteractive: Bool = false
    var onDrag: ((Double) -> Void)? = nil
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
                    .offset(x: min(CGFloat(fraction) * geometry.size.width, geometry.size.width - markerWidth))
                    .animation(isInteractive ? nil : .linear(duration: 1), value: fraction)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let clamped = min(max(value.location.x / geometry.size.width, 0), 1)
                        onDrag?(clamped)
                    },
                isEnabled: isInteractive
            )
        }
        .frame(height: 24)
    }
}
