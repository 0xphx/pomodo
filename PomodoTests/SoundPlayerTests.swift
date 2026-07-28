// PomodoTests/SoundPlayerTests.swift
import XCTest
import AppKit
@testable import Pomodo

final class SoundPlayerTests: XCTestCase {
    func testAllPresetsResolveToARealSystemSound() {
        for preset in SoundPreset.allCases {
            XCTAssertNotNil(NSSound(named: preset.rawValue), "Kein System-Sound für Preset \(preset.rawValue) gefunden")
        }
    }

    func testPlaySucceedsForEveryPreset() {
        let player = SoundPlayer()
        for preset in SoundPreset.allCases {
            XCTAssertTrue(player.play(preset), "Abspielen ist für Preset \(preset.rawValue) fehlgeschlagen")
        }
    }
}
