// Pomodo/Views/MenuBarView.swift
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var engine: TimerEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TickBarView(elapsedFraction: engine.elapsedFraction)
            ControlsRow(engine: engine)
            HStack {
                cycleIndicator
                Spacer()
                Text(engine.formattedRemaining)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: engine.remainingSeconds)
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(.ultraThinMaterial)
        .foregroundStyle(Color.primary)
    }

    private var cycleIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(engine.cyclesBeforeLongBreak, 1), id: \.self) { index in
                Circle()
                    .fill(index < engine.completedWorkCycles ? Color.primary : Color.primary.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }
}
