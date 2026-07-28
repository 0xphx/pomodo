// Pomodo/Views/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: TimerSettings

    var body: some View {
        Form {
            Section("Dauer") {
                Stepper("Arbeitsdauer: \(settings.workMinutes) min", value: $settings.workMinutes, in: 1...120)
                Stepper("Kurze Pause: \(settings.shortBreakMinutes) min", value: $settings.shortBreakMinutes, in: 1...60)
                Stepper("Lange Pause: \(settings.longBreakMinutes) min", value: $settings.longBreakMinutes, in: 1...120)
                Stepper("Zyklen bis lange Pause: \(settings.cyclesBeforeLongBreak)", value: $settings.cyclesBeforeLongBreak, in: 1...12)
            }
            Section("Sound") {
                Picker("Hinweiston", selection: $settings.soundPreset) {
                    ForEach(SoundPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
            }
            Section("Allgemein") {
                Toggle("Bei Login automatisch starten", isOn: launchAtLoginBinding)
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { settings.launchAtLogin },
            set: { newValue in
                settings.launchAtLogin = newValue
                LaunchAtLogin().setEnabled(newValue)
            }
        )
    }
}
