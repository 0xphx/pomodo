import Foundation

enum SoundPreset: String, CaseIterable, Identifiable {
    case glass = "Glass"
    case ping = "Ping"
    case pop = "Pop"
    case hero = "Hero"
    case submarine = "Submarine"

    var id: String { rawValue }
}

final class TimerSettings: ObservableObject {
    private enum Keys {
        static let workMinutes = "workMinutes"
        static let shortBreakMinutes = "shortBreakMinutes"
        static let longBreakMinutes = "longBreakMinutes"
        static let cyclesBeforeLongBreak = "cyclesBeforeLongBreak"
        static let soundPreset = "soundPreset"
        static let launchAtLogin = "launchAtLogin"
    }

    static let defaultWorkMinutes = 25
    static let defaultShortBreakMinutes = 5
    static let defaultLongBreakMinutes = 15
    static let defaultCyclesBeforeLongBreak = 4

    private let defaults: UserDefaults

    @Published var workMinutes: Int {
        didSet { defaults.set(workMinutes, forKey: Keys.workMinutes) }
    }
    @Published var shortBreakMinutes: Int {
        didSet { defaults.set(shortBreakMinutes, forKey: Keys.shortBreakMinutes) }
    }
    @Published var longBreakMinutes: Int {
        didSet { defaults.set(longBreakMinutes, forKey: Keys.longBreakMinutes) }
    }
    @Published var cyclesBeforeLongBreak: Int {
        didSet { defaults.set(cyclesBeforeLongBreak, forKey: Keys.cyclesBeforeLongBreak) }
    }
    @Published var soundPreset: SoundPreset {
        didSet { defaults.set(soundPreset.rawValue, forKey: Keys.soundPreset) }
    }
    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        workMinutes = defaults.object(forKey: Keys.workMinutes) as? Int ?? Self.defaultWorkMinutes
        shortBreakMinutes = defaults.object(forKey: Keys.shortBreakMinutes) as? Int ?? Self.defaultShortBreakMinutes
        longBreakMinutes = defaults.object(forKey: Keys.longBreakMinutes) as? Int ?? Self.defaultLongBreakMinutes
        cyclesBeforeLongBreak = defaults.object(forKey: Keys.cyclesBeforeLongBreak) as? Int ?? Self.defaultCyclesBeforeLongBreak
        let rawSound = defaults.string(forKey: Keys.soundPreset) ?? SoundPreset.glass.rawValue
        soundPreset = SoundPreset(rawValue: rawSound) ?? .glass
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
    }
}
