// PomodoTests/NotificationManagerTests.swift
import XCTest
@testable import Pomodo

final class NotificationManagerTests: XCTestCase {
    func testTitleDescribesFinishedPhase() {
        let manager = NotificationManager()
        XCTAssertEqual(manager.title(for: .work), "Arbeitsphase beendet")
        XCTAssertEqual(manager.title(for: .shortBreak), "Pause beendet")
        XCTAssertEqual(manager.title(for: .longBreak), "Lange Pause beendet")
    }

    func testBodyDescribesUpcomingPhase() {
        let manager = NotificationManager()
        XCTAssertEqual(manager.body(for: .work), "Zeit für die nächste Arbeitsphase.")
        XCTAssertEqual(manager.body(for: .shortBreak), "Zeit für eine kurze Pause.")
        XCTAssertEqual(manager.body(for: .longBreak), "Zeit für eine lange Pause.")
    }

    func testNotifyPhaseCompletedBuildsCorrectContent() {
        let manager = NotificationManager()

        // Test: work phase finished, short break next
        var content = manager.content(finished: .work, next: .shortBreak)
        XCTAssertEqual(content.title, "Arbeitsphase beendet")
        XCTAssertEqual(content.body, "Zeit für eine kurze Pause.")

        // Test: short break finished, work phase next
        content = manager.content(finished: .shortBreak, next: .work)
        XCTAssertEqual(content.title, "Pause beendet")
        XCTAssertEqual(content.body, "Zeit für die nächste Arbeitsphase.")

        // Test: long break finished, work phase next
        content = manager.content(finished: .longBreak, next: .work)
        XCTAssertEqual(content.title, "Lange Pause beendet")
        XCTAssertEqual(content.body, "Zeit für die nächste Arbeitsphase.")
    }
}
