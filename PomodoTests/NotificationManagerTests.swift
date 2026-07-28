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
}
