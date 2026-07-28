// Pomodo/Views/ControlsRow.swift
import SwiftUI
import AppKit

struct ControlsRow: View {
    @ObservedObject var engine: TimerEngine
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack {
            Button("cancel") { engine.cancel() }
            Button("restart") { engine.restart() }
            Spacer()
            Button(primaryButtonLabel) { primaryButtonAction() }
            Menu {
                Button("Einstellungen") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "settings")
                }
                Button("Skip") { engine.skip() }
                Button("Beenden") { NSApplication.shared.terminate(nil) }
            } label: {
                Text("...")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .buttonStyle(.plain)
    }

    private var primaryButtonLabel: String {
        if !engine.isRunning { return "start" }
        return engine.isPaused ? "resume" : "pause"
    }

    private func primaryButtonAction() {
        if !engine.isRunning {
            engine.start()
        } else if engine.isPaused {
            engine.resume()
        } else {
            engine.pause()
        }
    }
}
