// Pomodo/Views/MenuBarLabelView.swift
import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var engine: TimerEngine

    var body: some View {
        if engine.isRunning {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text(engine.formattedRemaining)
                    .font(.system(.body, design: .monospaced))
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: engine.remainingSeconds)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.black))
            .foregroundStyle(Color.white)
        } else {
            Image(systemName: "timer")
        }
    }
}
