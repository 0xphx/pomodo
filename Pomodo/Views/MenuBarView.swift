// Pomodo/Views/MenuBarView.swift
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var engine: TimerEngine
    @State private var isEditingCustomDuration = false
    @State private var customDurationText = ""
    @FocusState private var isDurationFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TickBarView(
                fraction: engine.isRunning ? engine.elapsedFraction : engine.idleFraction,
                isInteractive: !engine.isRunning && !isEditingCustomDuration,
                onDrag: { fraction in
                    let minutes = min(max(Int((fraction * 60).rounded()), 1), 60)
                    engine.setPendingCustomWorkMinutes(minutes)
                }
            )
            ControlsRow(engine: engine)
            HStack {
                cycleIndicator
                Spacer()
                countdownArea
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(.ultraThinMaterial)
        .foregroundStyle(Color.primary)
        .onChange(of: engine.isRunning) { _, isRunning in
            if isRunning {
                isEditingCustomDuration = false
            }
        }
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

    @ViewBuilder
    private var countdownArea: some View {
        HStack(spacing: 8) {
            if showsCustomDurationEditor && !isEditingCustomDuration {
                Button {
                    customDurationText = String(engine.idlePreviewMinutes)
                    isEditingCustomDuration = true
                    isDurationFieldFocused = true
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
            }

            if isEditingCustomDuration {
                TextField("Minuten", text: $customDurationText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .frame(width: 90)
                    .multilineTextAlignment(.trailing)
                    .focused($isDurationFieldFocused)
                    .onSubmit(commitCustomDuration)
            } else {
                Text(engine.formattedDisplay)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: engine.formattedDisplay)
            }
        }
    }

    private var showsCustomDurationEditor: Bool {
        !engine.isRunning && engine.idlePreviewMinutes >= 60
    }

    private func commitCustomDuration() {
        if let minutes = Int(customDurationText), minutes > 0 {
            engine.setPendingCustomWorkMinutes(min(minutes, 999))
        }
        isEditingCustomDuration = false
    }
}
