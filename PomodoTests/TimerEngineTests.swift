// PomodoTests/TimerEngineTests.swift
import XCTest
@testable import Pomodo

final class TimerEngineTests: XCTestCase {
    final class TestClock {
        var currentDate: Date
        init(_ date: Date = Date(timeIntervalSince1970: 0)) { currentDate = date }
        func now() -> Date { currentDate }
        func advance(_ seconds: TimeInterval) { currentDate.addTimeInterval(seconds) }
    }

    private func makeSettings(work: Int = 25, short: Int = 5, long: Int = 15, cycles: Int = 4) -> TimerSettings {
        let suiteName = "TimerEngineTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let settings = TimerSettings(defaults: defaults)
        settings.workMinutes = work
        settings.shortBreakMinutes = short
        settings.longBreakMinutes = long
        settings.cyclesBeforeLongBreak = cycles
        return settings
    }

    func testStartSetsTotalAndRemainingFromWorkDuration() {
        let engine = TimerEngine(settings: makeSettings(work: 25))
        engine.start()
        XCTAssertEqual(engine.totalSeconds, 25 * 60)
        XCTAssertEqual(engine.remainingSeconds, 25 * 60)
        XCTAssertTrue(engine.isRunning)
        XCTAssertEqual(engine.phase, .work)
    }

    func testTickReducesRemainingSecondsUsingInjectedClock() {
        let clock = TestClock()
        let engine = TimerEngine(settings: makeSettings(work: 25), now: clock.now)
        engine.start()
        clock.advance(10)
        engine.tick()
        XCTAssertEqual(engine.remainingSeconds, 25 * 60 - 10)
    }

    func testWorkPhaseAdvancesToShortBreakAfterCompletion() {
        let clock = TestClock()
        let engine = TimerEngine(settings: makeSettings(work: 1, short: 1, long: 1, cycles: 4), now: clock.now)
        engine.start()
        clock.advance(61)
        engine.tick()
        XCTAssertEqual(engine.phase, .shortBreak)
        XCTAssertEqual(engine.completedWorkCycles, 1)
        XCTAssertEqual(engine.remainingSeconds, 60)
        XCTAssertTrue(engine.isRunning)
    }

    func testLongBreakAfterConfiguredCycleCountThenResets() {
        let clock = TestClock()
        let engine = TimerEngine(settings: makeSettings(work: 1, short: 1, long: 1, cycles: 2), now: clock.now)
        engine.start()
        clock.advance(61); engine.tick()
        XCTAssertEqual(engine.phase, .shortBreak)
        XCTAssertEqual(engine.completedWorkCycles, 1)

        clock.advance(61); engine.tick()
        XCTAssertEqual(engine.phase, .work)

        clock.advance(61); engine.tick()
        XCTAssertEqual(engine.phase, .longBreak)
        XCTAssertEqual(engine.completedWorkCycles, 2)

        clock.advance(61); engine.tick()
        XCTAssertEqual(engine.phase, .work)
        XCTAssertEqual(engine.completedWorkCycles, 0)
    }

    func testPauseFreezesRemainingAndResumeContinuesFromSamePoint() {
        let clock = TestClock()
        let engine = TimerEngine(settings: makeSettings(work: 25), now: clock.now)
        engine.start()
        clock.advance(10); engine.tick()
        engine.pause()
        XCTAssertTrue(engine.isPaused)

        clock.advance(500)
        engine.resume()
        XCTAssertFalse(engine.isPaused)
        XCTAssertEqual(engine.remainingSeconds, 25 * 60 - 10)

        clock.advance(5); engine.tick()
        XCTAssertEqual(engine.remainingSeconds, 25 * 60 - 15)
    }

    func testRestartResetsCurrentPhaseFromScratch() {
        let clock = TestClock()
        let engine = TimerEngine(settings: makeSettings(work: 25), now: clock.now)
        engine.start()
        clock.advance(100); engine.tick()
        engine.restart()
        XCTAssertEqual(engine.remainingSeconds, 25 * 60)
        XCTAssertEqual(engine.phase, .work)
        XCTAssertFalse(engine.isPaused)
        XCTAssertTrue(engine.isRunning)
    }

    func testCancelResetsToIdleWorkState() {
        let clock = TestClock()
        let engine = TimerEngine(settings: makeSettings(work: 25), now: clock.now)
        engine.start()
        clock.advance(100); engine.tick()
        engine.cancel()
        XCTAssertFalse(engine.isRunning)
        XCTAssertFalse(engine.isPaused)
        XCTAssertEqual(engine.phase, .work)
        XCTAssertEqual(engine.remainingSeconds, 25 * 60)
        XCTAssertEqual(engine.completedWorkCycles, 0)
    }

    func testSkipEndsPhaseImmediatelyAndAdvances() {
        let engine = TimerEngine(settings: makeSettings(work: 25, short: 5))
        engine.start()
        engine.skip()
        XCTAssertEqual(engine.phase, .shortBreak)
        XCTAssertEqual(engine.remainingSeconds, 5 * 60)
        XCTAssertTrue(engine.isRunning)
    }

    func testOnPhaseCompletedCallbackFiresWithFinishedAndNextPhase() {
        let clock = TestClock()
        let engine = TimerEngine(settings: makeSettings(work: 1, short: 1), now: clock.now)
        var received: (TimerPhase, TimerPhase)?
        engine.onPhaseCompleted = { finished, next in received = (finished, next) }
        engine.start()
        clock.advance(61); engine.tick()
        XCTAssertEqual(received?.0, .work)
        XCTAssertEqual(received?.1, .shortBreak)
    }

    func testElapsedFractionReflectsProgress() {
        let clock = TestClock()
        let engine = TimerEngine(settings: makeSettings(work: 1), now: clock.now)
        engine.start()
        XCTAssertEqual(engine.elapsedFraction, 0, accuracy: 0.0001)
        clock.advance(30); engine.tick()
        XCTAssertEqual(engine.elapsedFraction, 0.5, accuracy: 0.0001)
    }

    func testFormattedRemainingUsesMMSSWithLeadingZeros() {
        let clock = TestClock()
        let engine = TimerEngine(settings: makeSettings(work: 5), now: clock.now)
        engine.start()
        clock.advance(268); engine.tick()
        XCTAssertEqual(engine.formattedRemaining, "00:32")
    }
}
