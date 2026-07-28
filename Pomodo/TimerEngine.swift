// Pomodo/TimerEngine.swift
import Foundation

final class TimerEngine: ObservableObject {
    @Published private(set) var phase: TimerPhase = .work
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var totalSeconds: Int
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var completedWorkCycles: Int = 0
    @Published private(set) var pendingCustomWorkMinutes: Int?

    var onPhaseCompleted: ((TimerPhase, TimerPhase) -> Void)?

    private let settings: TimerSettings
    private let now: () -> Date
    private var endDate: Date?
    private var pausedRemainingSeconds: Int?
    private var ticker: Timer?

    var cyclesBeforeLongBreak: Int { settings.cyclesBeforeLongBreak }

    var idlePreviewMinutes: Int { pendingCustomWorkMinutes ?? settings.workMinutes }
    var idlePreviewSeconds: Int { idlePreviewMinutes * 60 }
    var idleFraction: Double { min(Double(idlePreviewMinutes) / 60.0, 1.0) }

    var elapsedFraction: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1 - (Double(remainingSeconds) / Double(totalSeconds))
    }

    var formattedRemaining: String { Self.format(seconds: remainingSeconds) }

    var formattedDisplay: String {
        Self.format(seconds: isRunning ? remainingSeconds : idlePreviewSeconds)
    }

    init(settings: TimerSettings, now: @escaping () -> Date = Date.init) {
        self.settings = settings
        self.now = now
        let initialTotal = settings.workMinutes * 60
        totalSeconds = initialTotal
        remainingSeconds = initialTotal
    }

    deinit {
        ticker?.invalidate()
    }

    func start() {
        guard !isRunning else { return }
        beginPhase(phase)
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        pausedRemainingSeconds = remainingSeconds
        endDate = nil
        isPaused = true
        stopTicker()
    }

    func resume() {
        guard isRunning, isPaused, let remaining = pausedRemainingSeconds else { return }
        endDate = now().addingTimeInterval(TimeInterval(remaining))
        isPaused = false
        pausedRemainingSeconds = nil
        startTicker()
    }

    func restart() {
        beginPhase(phase)
    }

    func cancel() {
        stopTicker()
        isRunning = false
        isPaused = false
        endDate = nil
        pausedRemainingSeconds = nil
        phase = .work
        completedWorkCycles = 0
        pendingCustomWorkMinutes = nil
        totalSeconds = duration(for: phase)
        remainingSeconds = totalSeconds
    }

    func skip() {
        guard isRunning else { return }
        advancePhase()
    }

    func tick() {
        guard let endDate else { return }
        let remaining = Int(ceil(endDate.timeIntervalSince(now())))
        if remaining <= 0 {
            remainingSeconds = 0
            advancePhase()
        } else {
            remainingSeconds = remaining
        }
    }

    func setPendingCustomWorkMinutes(_ minutes: Int) {
        guard !isRunning else { return }
        pendingCustomWorkMinutes = max(1, minutes)
    }

    private func beginPhase(_ phase: TimerPhase) {
        let seconds: Int
        if phase == .work, let custom = pendingCustomWorkMinutes {
            seconds = custom * 60
            pendingCustomWorkMinutes = nil
        } else {
            seconds = duration(for: phase)
        }
        totalSeconds = seconds
        remainingSeconds = seconds
        endDate = now().addingTimeInterval(TimeInterval(seconds))
        isRunning = true
        isPaused = false
        pausedRemainingSeconds = nil
        startTicker()
    }

    private func advancePhase() {
        let finishedPhase = phase
        let nextPhase: TimerPhase
        if finishedPhase == .work {
            completedWorkCycles += 1
            nextPhase = completedWorkCycles >= settings.cyclesBeforeLongBreak ? .longBreak : .shortBreak
        } else {
            if finishedPhase == .longBreak {
                completedWorkCycles = 0
            }
            nextPhase = .work
        }
        phase = nextPhase
        onPhaseCompleted?(finishedPhase, nextPhase)
        beginPhase(nextPhase)
    }

    private func duration(for phase: TimerPhase) -> Int {
        switch phase {
        case .work: return settings.workMinutes * 60
        case .shortBreak: return settings.shortBreakMinutes * 60
        case .longBreak: return settings.longBreakMinutes * 60
        }
    }

    private static func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func startTicker() {
        stopTicker()
        let newTicker = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(newTicker, forMode: .common)
        ticker = newTicker
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }
}
