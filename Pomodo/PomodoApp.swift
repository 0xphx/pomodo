// Pomodo/PomodoApp.swift
import SwiftUI
import UserNotifications

@main
struct PomodoApp: App {
    @StateObject private var settings: TimerSettings
    @StateObject private var engine: TimerEngine
    private let notificationPresenter = NotificationPresenter()

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

        UNUserNotificationCenter.current().delegate = notificationPresenter
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
