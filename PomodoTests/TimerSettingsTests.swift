import XCTest
@testable import Pomodo

final class TimerSettingsTests: XCTestCase {
    private func freshDefaults() -> UserDefaults {
        let suiteName = "TimerSettingsTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    func testDefaultsMatchSpec() {
        let settings = TimerSettings(defaults: freshDefaults())
        XCTAssertEqual(settings.workMinutes, 25)
        XCTAssertEqual(settings.shortBreakMinutes, 5)
        XCTAssertEqual(settings.longBreakMinutes, 15)
        XCTAssertEqual(settings.cyclesBeforeLongBreak, 4)
        XCTAssertEqual(settings.soundPreset, .glass)
        XCTAssertEqual(settings.launchAtLogin, false)
    }

    func testChangesPersistAcrossInstancesUsingSameDefaults() {
        let defaults = freshDefaults()
        let first = TimerSettings(defaults: defaults)
        first.workMinutes = 45
        first.soundPreset = .hero
        first.launchAtLogin = true

        let second = TimerSettings(defaults: defaults)
        XCTAssertEqual(second.workMinutes, 45)
        XCTAssertEqual(second.soundPreset, .hero)
        XCTAssertEqual(second.launchAtLogin, true)
    }
}
