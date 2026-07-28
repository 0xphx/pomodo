// Pomodo/PomodoApp.swift
import SwiftUI

@main
struct PomodoApp: App {
    @StateObject private var settings: TimerSettings
    @StateObject private var engine: TimerEngine

    init() {
        let settings = TimerSettings()
        let engine = TimerEngine(settings: settings)
        let soundPlayer = SoundPlayer()
        let notificationManager = NotificationManager()

        engine.onPhaseCompleted = { finished, next in
            soundPlayer.play(settings.soundPreset)
            notificationManager.notifyPhaseCompleted(finished: finished, next: next)
        }

        _settings = StateObject(wrappedValue: settings)
        _engine = StateObject(wrappedValue: engine)

        notificationManager.requestAuthorization()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(engine: engine)
        } label: {
            MenuBarLabelView(engine: engine)
        }
        .menuBarExtraStyle(.window)

        Window("Einstellungen", id: "settings") {
            SettingsView(settings: settings)
        }
        .windowResizability(.contentSize)
    }
}
