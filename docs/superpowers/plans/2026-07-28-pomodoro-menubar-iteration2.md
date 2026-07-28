# Pomodo Menüleiste — Iteration 2 (interaktive Tick-Leiste & Vereinfachung) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vier UI/UX-Verbesserungen an der bereits gemergten Pomodo-App: kein Icon mehr in der Menüleiste (nur Text), verschiebbare Tick-Leiste zum einmaligen Einstellen einer eigenen Arbeitsdauer (1–60 Min, mit manueller Texteingabe darüber hinaus), und ein bereinigtes "..."-Menü (nur noch Chevron statt Doppel-Icon).

**Architecture:** Alle Änderungen bleiben innerhalb der bestehenden Architektur (`TimerEngine` bleibt einzige Quelle der Wahrheit). `TimerEngine` bekommt eine neue, nicht-persistente Property `pendingCustomWorkMinutes` plus drei rein lesende Idle-Preview-Properties. `TickBarView` bekommt einen optionalen Interaktions-Modus (Drag-Geste), der nur im Idle-Zustand aktiviert wird. Views bleiben reine Presentational Views ohne eigene Business-Logik — die Umrechnung Drag-Position → Minuten passiert im View (`MenuBarView`), das Merken/Konsumieren der Custom-Dauer passiert im Engine.

**Tech Stack:** Swift, SwiftUI (macOS 14+), XCTest — identisch zum bestehenden Projekt, keine neuen Abhängigkeiten.

## Global Constraints

- Deployment-Target bleibt macOS 14.0+, Xcode 16+ (unverändert).
- Keine neuen Swift-Package-Abhängigkeiten.
- Build-/Test-Kommandos brauchen weiterhin den Prefix `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- **Wichtig (wiederkehrender Bug in Iteration 1):** Dieses Projekt nutzt XcodeGen (`project.yml` → `xcodegen generate` → `Pomodo.xcodeproj/project.pbxproj`, klassische, nicht dateisystem-synchronisierte Registrierung). Alle Tasks in diesem Plan **modifizieren nur bestehende Dateien** (keine neuen Swift-Dateien) — daher ist normalerweise **keine** `project.pbxproj`-Änderung nötig. Trotzdem nach jeder Task `git status --short` prüfen; falls doch eine pbxproj-Änderung auftaucht, das genau begründen, bevor committed wird.
- **Jeder Task-Commit muss den Gesamt-Build grün halten** — deshalb sind API-ändernde Dateien (`TickBarView`) und ihr einziger Call-Site (`MenuBarView`) in einem gemeinsamen Task (Task 2), nicht getrennt.
- Commit-Messages im Conventional-Commits-Stil.
- Arbeiten auf einem Feature-Branch (LEICHT-Workflow, mehrdatei-Änderung), z. B. `feature/menubar-iteration2`.
- Bezugs-Spec: `docs/superpowers/specs/2026-07-28-pomodoro-menubar-app-design.md`, Abschnitt 13 (Iteration 2) — dort stehen alle Verhaltensdetails, die hier referenziert werden.

---

### Task 1: TimerEngine — Custom-Dauer-Vorschau & einmalige Override-Logik

**Files:**
- Modify: `Pomodo/TimerEngine.swift` (komplett ersetzen, siehe Step 3)
- Modify: `PomodoTests/TimerEngineTests.swift` (neue Testmethoden ergänzen, siehe Step 1)

**Interfaces:**
- Consumes: nichts Neues (nutzt weiterhin `TimerSettings`, `TimerPhase` aus Tasks der ersten Iteration)
- Produces (neu, von Task 2 in diesem Plan genutzt):
  - `@Published private(set) var pendingCustomWorkMinutes: Int?`
  - `var idlePreviewMinutes: Int { get }`
  - `var idlePreviewSeconds: Int { get }`
  - `var idleFraction: Double { get }` (0...1, Minuten/60, geclampt)
  - `var formattedDisplay: String { get }` (zeigt `remainingSeconds` wenn `isRunning`, sonst `idlePreviewSeconds`)
  - `func setPendingCustomWorkMinutes(_ minutes: Int)` (no-op wenn `isRunning`; clampt auf mindestens 1)
  - `formattedRemaining` bleibt unverändert bestehen (wird weiterhin von `MenuBarLabelView` benutzt)

- [ ] **Step 1: Neue Tests an `PomodoTests/TimerEngineTests.swift` anhängen**

Füge diese Testmethoden **innerhalb** der Klasse `TimerEngineTests`, vor der schließenden `}` der Klasse (nach `testFormattedRemainingUsesMMSSWithLeadingZeros`) ein:

```swift
    func testIdlePreviewDefaultsToSettingsWorkMinutes() {
        let engine = TimerEngine(settings: makeSettings(work: 25))
        XCTAssertEqual(engine.idlePreviewMinutes, 25)
        XCTAssertEqual(engine.idlePreviewSeconds, 25 * 60)
        XCTAssertEqual(engine.formattedDisplay, "25:00")
    }

    func testSetPendingCustomWorkMinutesOverridesIdlePreview() {
        let engine = TimerEngine(settings: makeSettings(work: 25))
        engine.setPendingCustomWorkMinutes(12)
        XCTAssertEqual(engine.idlePreviewMinutes, 12)
        XCTAssertEqual(engine.formattedDisplay, "12:00")
    }

    func testSetPendingCustomWorkMinutesClampsToAtLeastOne() {
        let engine = TimerEngine(settings: makeSettings(work: 25))
        engine.setPendingCustomWorkMinutes(0)
        XCTAssertEqual(engine.idlePreviewMinutes, 1)
    }

    func testSetPendingCustomWorkMinutesIgnoredWhileRunning() {
        let engine = TimerEngine(settings: makeSettings(work: 25))
        engine.start()
        engine.setPendingCustomWorkMinutes(12)
        XCTAssertNil(engine.pendingCustomWorkMinutes)
    }

    func testStartConsumesPendingCustomWorkMinutesOnce() {
        let engine = TimerEngine(settings: makeSettings(work: 25, short: 5))
        engine.setPendingCustomWorkMinutes(12)
        engine.start()
        XCTAssertEqual(engine.totalSeconds, 12 * 60)
        XCTAssertNil(engine.pendingCustomWorkMinutes)
    }

    func testPendingCustomWorkMinutesDoesNotReapplyToSubsequentWorkPhase() {
        let clock = TestClock()
        let engine = TimerEngine(settings: makeSettings(work: 25, short: 1), now: clock.now)
        engine.setPendingCustomWorkMinutes(1)
        engine.start()
        XCTAssertEqual(engine.totalSeconds, 60)
        clock.advance(61); engine.tick() // work (1 min custom) done -> shortBreak
        clock.advance(61); engine.tick() // shortBreak done -> work again, sollte wieder Settings-Standard (25) nutzen
        XCTAssertEqual(engine.phase, .work)
        XCTAssertEqual(engine.totalSeconds, 25 * 60)
    }

    func testCancelClearsPendingCustomWorkMinutes() {
        let engine = TimerEngine(settings: makeSettings(work: 25))
        engine.setPendingCustomWorkMinutes(9)
        engine.cancel()
        XCTAssertNil(engine.pendingCustomWorkMinutes)
    }

    func testIdleFractionReflectsMinutesOutOf60() {
        let engine = TimerEngine(settings: makeSettings(work: 25))
        engine.setPendingCustomWorkMinutes(30)
        XCTAssertEqual(engine.idleFraction, 0.5, accuracy: 0.0001)
    }

    func testIdleFractionClampsAtOneForValuesAtOrAbove60() {
        let engine = TimerEngine(settings: makeSettings(work: 25))
        engine.setPendingCustomWorkMinutes(90)
        XCTAssertEqual(engine.idleFraction, 1.0, accuracy: 0.0001)
    }

    func testFormattedDisplayShowsLiveRemainingWhileRunning() {
        let clock = TestClock()
        let engine = TimerEngine(settings: makeSettings(work: 25), now: clock.now)
        engine.start()
        clock.advance(10); engine.tick()
        XCTAssertEqual(engine.formattedDisplay, engine.formattedRemaining)
    }
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS' -only-testing:PomodoTests/TimerEngineTests`
Expected: FAIL — die neuen Properties/Methoden existieren noch nicht.

- [ ] **Step 3: `Pomodo/TimerEngine.swift` komplett ersetzen**

```swift
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
```

Hinweis: `duration(for:)` bleibt unverändert (wird weiterhin für `.shortBreak`/`.longBreak` und als Fallback für `.work` ohne Pending-Override genutzt). Der neue Zweig in `beginPhase` konsumiert `pendingCustomWorkMinutes` **nur** wenn `phase == .work` — bei Pausen ist eine Custom-Dauer ohnehin nie gesetzt gewesen (siehe `setPendingCustomWorkMinutes`-Guard).

- [ ] **Step 4: Tests laufen lassen, Erfolg verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS' -only-testing:PomodoTests/TimerEngineTests`
Expected: `** TEST SUCCEEDED **`, alle (bisherigen + 9 neuen) Tests grün.

- [ ] **Step 5: `git status --short` prüfen**

Erwartet: nur `Pomodo/TimerEngine.swift` und `PomodoTests/TimerEngineTests.swift` verändert, **keine** `project.pbxproj`-Änderung (reine Datei-Modifikation, kein neuer Dateipfad).

- [ ] **Step 6: Commit**

```bash
git add Pomodo/TimerEngine.swift PomodoTests/TimerEngineTests.swift
git commit -m "feat: add one-time custom work-duration override to TimerEngine"
```

---

### Task 2: TickBarView (interaktiver Drag-Modus) + MenuBarView-Verdrahtung

Zusammengelegt aus einer früheren Plan-Fassung, weil `TickBarView`s Signaturänderung und ihr einziger Call-Site (`MenuBarView`) sich gegenseitig bedingen — getrennt committed würde ein Zwischenstand entstehen, der nicht baut.

**Files:**
- Modify: `Pomodo/Views/TickBarView.swift` (komplett ersetzen, siehe Step 1)
- Modify: `Pomodo/Views/MenuBarView.swift` (komplett ersetzen, siehe Step 2)

**Interfaces:**
- Consumes: `TimerEngine` (aus Task 1: `idleFraction`, `idlePreviewMinutes`, `formattedDisplay`, `setPendingCustomWorkMinutes(_:)`, plus bestehende `elapsedFraction`, `isRunning`, `cyclesBeforeLongBreak`, `completedWorkCycles`)
- Produces:
  - `TickBarView(fraction: Double, isInteractive: Bool = false, onDrag: ((Double) -> Void)? = nil)` (ersetzt die bisherige Signatur `TickBarView(elapsedFraction:)`)
  - `MenuBarView(engine:)` — äußere Signatur unverändert, Inhalt neu
- Kein automatisierter Test (reine SwiftUI-Darstellung inkl. Geste, manuell verifiziert — wie schon in Iteration 1).

- [ ] **Step 1: `Pomodo/Views/TickBarView.swift` komplett ersetzen**

```swift
// Pomodo/Views/TickBarView.swift
import SwiftUI

struct TickBarView: View {
    let fraction: Double
    var isInteractive: Bool = false
    var onDrag: ((Double) -> Void)? = nil
    private let tickCount = 60
    private let markerWidth: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Canvas { context, size in
                    let tickWidth: CGFloat = 1.5
                    let spacing = size.width / CGFloat(tickCount)
                    for index in 0..<tickCount {
                        let x = CGFloat(index) * spacing
                        let rect = CGRect(x: x, y: 0, width: tickWidth, height: size.height)
                        context.fill(Path(rect), with: .color(.gray.opacity(0.4)))
                    }
                }

                Rectangle()
                    .fill(Color.red)
                    .frame(width: markerWidth)
                    .offset(x: min(CGFloat(fraction) * geometry.size.width, geometry.size.width - markerWidth))
                    .animation(isInteractive ? nil : .linear(duration: 1), value: fraction)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let clamped = min(max(value.location.x / geometry.size.width, 0), 1)
                        onDrag?(clamped)
                    },
                isEnabled: isInteractive
            )
        }
        .frame(height: 24)
    }
}
```

Wichtige Details:
- `.animation(isInteractive ? nil : .linear(duration: 1), value: fraction)` — im interaktiven (Idle-)Modus **keine** Animation, damit der Marker dem Cursor/Finger sofort folgt statt einer Sekunde hinterherzuhinken; im nicht-interaktiven (laufenden) Modus bleibt die bisherige sanfte 1-Sekunden-Animation erhalten.
- `.gesture(_:isEnabled:)` (verfügbar ab macOS 14) aktiviert/deaktiviert die Drag-Geste komplett, statt mit einem optionalen Gesture-Wert zu hantieren.
- `DragGesture(minimumDistance: 0)` erkennt auch einen reinen Klick (ohne Bewegung) als Sprung an die geklickte Position.

- [ ] **Step 2: `Pomodo/Views/MenuBarView.swift` komplett ersetzen**

```swift
// Pomodo/Views/MenuBarView.swift
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var engine: TimerEngine
    @State private var isEditingCustomDuration = false
    @State private var customDurationText = ""
    @FocusState private var isDurationFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TickBarView(
                fraction: engine.isRunning ? engine.elapsedFraction : engine.idleFraction,
                isInteractive: !engine.isRunning,
                onDrag: { fraction in
                    let minutes = min(max(Int((fraction * 60).rounded()), 1), 60)
                    engine.setPendingCustomWorkMinutes(minutes)
                }
            )
            ControlsRow(engine: engine)
            HStack {
                cycleIndicator
                Spacer()
                countdownArea
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(.ultraThinMaterial)
        .foregroundStyle(Color.primary)
    }

    private var cycleIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(engine.cyclesBeforeLongBreak, 1), id: \.self) { index in
                Circle()
                    .fill(index < engine.completedWorkCycles ? Color.primary : Color.primary.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }

    @ViewBuilder
    private var countdownArea: some View {
        HStack(spacing: 8) {
            if showsCustomDurationEditor && !isEditingCustomDuration {
                Button {
                    customDurationText = String(engine.idlePreviewMinutes)
                    isEditingCustomDuration = true
                    isDurationFieldFocused = true
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
            }

            if isEditingCustomDuration {
                TextField("Minuten", text: $customDurationText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .frame(width: 90)
                    .multilineTextAlignment(.trailing)
                    .focused($isDurationFieldFocused)
                    .onSubmit(commitCustomDuration)
            } else {
                Text(engine.formattedDisplay)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: engine.formattedDisplay)
            }
        }
    }

    private var showsCustomDurationEditor: Bool {
        !engine.isRunning && engine.idlePreviewMinutes >= 60
    }

    private func commitCustomDuration() {
        if let minutes = Int(customDurationText), minutes > 0 {
            engine.setPendingCustomWorkMinutes(min(minutes, 999))
        }
        isEditingCustomDuration = false
    }
}
```

Wichtige Details:
- `TickBarView`s `fraction` kommt im laufenden Zustand aus `engine.elapsedFraction` (wie bisher), im Idle-Zustand aus `engine.idleFraction` (neu) — der `onDrag`-Callback ist nur relevant, wenn `isInteractive == true` (also im Idle-Zustand), da die Geste sonst deaktiviert ist.
- Die große Countdown-Zahl nutzt `engine.formattedDisplay` (nicht mehr `formattedRemaining`), damit sie im Idle-Zustand die Vorschau-Dauer zeigt statt eines eingefrorenen Werts.
- `.animation(.default, value: engine.formattedDisplay)` (ein `String`-Wert) statt `value: engine.remainingSeconds` — dadurch löst die Ziffern-Animation sowohl bei laufendem Countdown als auch beim Ziehen im Idle-Zustand aus. Bekannte kleine Einschränkung: `.numericText(countsDown: true)` ist für abnehmende Werte optimiert; zieht man im Idle-Zustand nach rechts (Wert steigt), rollen die Ziffern trotzdem in "Countdown"-Richtung — rein kosmetisch, kein Verhaltensfehler, in dieser Iteration bewusst nicht weiter optimiert.
- Das Stift-Icon erscheint ausschließlich, wenn `!engine.isRunning && engine.idlePreviewMinutes >= 60` (rechter Anschlag der Leiste) und der Editor nicht schon offen ist.
- `commitCustomDuration()` ignoriert ungültige Eingaben (kein Int, oder ≤ 0) still — der Editor schließt trotzdem, ohne die bisherige `pendingCustomWorkMinutes` zu verändern. Werte werden zusätzlich auf maximal 999 Minuten gedeckelt.

- [ ] **Step 3: Build verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Vollständige Testsuite laufen lassen**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS'`
Expected: `** TEST SUCCEEDED **`, alle Tests (inkl. der 9 neuen aus Task 1) grün.

- [ ] **Step 5: `git status --short` prüfen**

Erwartet: nur `Pomodo/Views/TickBarView.swift` und `Pomodo/Views/MenuBarView.swift` verändert, keine `project.pbxproj`-Änderung.

- [ ] **Step 6: Commit**

```bash
git add Pomodo/Views/TickBarView.swift Pomodo/Views/MenuBarView.swift
git commit -m "feat: add interactive tick bar with idle preview and manual duration entry"
```

---

### Task 3: MenuBarLabelView — Icon entfernen, reine Text-Anzeige

**Files:**
- Modify: `Pomodo/Views/MenuBarLabelView.swift` (komplett ersetzen)

**Interfaces:**
- Consumes: `TimerEngine` (`isRunning`, `formattedRemaining`, `remainingSeconds`) — unverändert
- Produces: `MenuBarLabelView(engine:)` — Signatur unverändert, nur der Inhalt ändert sich
- Kein automatisierter Test (reine SwiftUI-Darstellung, manuell verifiziert).

- [ ] **Step 1: `Pomodo/Views/MenuBarLabelView.swift` komplett ersetzen**

```swift
// Pomodo/Views/MenuBarLabelView.swift
import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var engine: TimerEngine

    var body: some View {
        if engine.isRunning {
            Text(engine.formattedRemaining)
                .font(.system(.body, design: .monospaced))
                .contentTransition(.numericText(countsDown: true))
                .animation(.default, value: engine.remainingSeconds)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.black))
                .foregroundStyle(Color.white)
        } else {
            Text("00:00")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}
```

Kein SF-Symbol-Icon mehr in beiden Zuständen (siehe Design-Spec Abschnitt 13.1). Idle zeigt immer literal `"00:00"`, unabhängig von einer evtl. im Panel gewählten Vorschau-Dauer.

- [ ] **Step 2: Build verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodo/Views/MenuBarLabelView.swift
git commit -m "feat: remove icon from menu bar label, show plain countdown text"
```

---

### Task 4: ControlsRow — "..."-Menü durch reinen Chevron ersetzen

**Files:**
- Modify: `Pomodo/Views/ControlsRow.swift` (gezielte Änderung, siehe Step 1)

**Interfaces:**
- Consumes: `TimerEngine` — unverändert
- Produces: `ControlsRow(engine:)` — Signatur unverändert
- Kein automatisierter Test (reine SwiftUI-Darstellung, manuell verifiziert).

- [ ] **Step 1: Menu-Label und Indicator anpassen**

In `Pomodo/Views/ControlsRow.swift`, ersetze:

```swift
            } label: {
                Text("...")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
```

durch:

```swift
            } label: {
                Image(systemName: "chevron.down")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
```

Der Rest der Datei (Menü-Inhalt: Einstellungen/Skip/Beenden, die beiden anderen Buttons, `primaryButtonLabel`/`primaryButtonAction`) bleibt unverändert.

- [ ] **Step 2: Build verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodo/Views/ControlsRow.swift
git commit -m "fix: replace ellipsis-plus-chevron menu trigger with a single chevron"
```

---

### Task 5: Manuelle End-to-End-Verifikation & Dokumentation

**Files:**
- Modify: `ROADMAP.md`

**Interfaces:**
- Consumes: die vollständige, zusammengesetzte App aus Tasks 1–4
- Produces: nichts Neues, nur Verifikation + Doku-Update

- [ ] **Step 1: Build & volle Testsuite ein letztes Mal verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS'`
Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS'`
Expected: beide `** ... SUCCEEDED **`

- [ ] **Step 2: Manueller Check in Xcode (Cmd+R)**

Prüfe im laufenden Betrieb:
- Menüleiste zeigt im Idle-Zustand nur `"00:00"` (grau), kein Icon
- Menüleiste zeigt im laufenden Zustand nur den Countdown in der dunklen Pille, kein Icon
- Im Panel (Idle-Zustand): Ziehen/Klicken auf der Tick-Leiste ändert die große Countdown-Zahl live in 1-Minuten-Schritten zwischen 1 und 60
- Bei 60 Minuten erscheint ein Stift-Icon; Antippen macht die Zahl editierbar, Eingabe z. B. "90" + Enter übernimmt 90 Minuten (Countdown-Zahl zeigt danach "90:00")
- "start" mit einer per Drag gewählten Dauer (z. B. 3 Minuten zum schnellen Testen) startet tatsächlich mit dieser Dauer; nach Ablauf und automatischem Wechsel zur Pause und zurück zur nächsten Arbeitsphase gilt wieder die Standard-Arbeitsdauer aus den Einstellungen (nicht die einmalige Custom-Dauer)
- "..."-Menü zeigt nur noch einen Chevron (kein "..." + Chevron nebeneinander), Menü-Inhalt (Einstellungen/Skip/Beenden) funktioniert weiterhin
- Sowohl in Light Mode als auch Dark Mode geprüft

- [ ] **Step 3: `ROADMAP.md` aktualisieren**

Verschiebe den entsprechenden Eintrag von "Geplant" (falls dort einer für diese Iteration existiert) nach "Erledigt", bzw. füge neu hinzu:

```markdown
## Erledigt
- [x] Pomodoro-Menüleisten-App (Grundgerüst, TimerEngine, UI, Settings, Sound/Notifications) (2026-07-28)
- [x] Menüleisten-Vereinfachung (kein Icon mehr) & interaktive Tick-Leiste mit einmaliger Custom-Dauer (2026-07-28)
```

- [ ] **Step 4: Commit**

```bash
git add ROADMAP.md
git commit -m "docs: mark menu bar iteration 2 as done in roadmap"
```

---

## Self-Review-Notizen (bereits durchgeführt)

- **Spec-Abdeckung:** Alle vier Punkte aus Design-Spec Abschnitt 13 sind auf Tasks gemappt (13.1 → Task 3, 13.2 → Task 4, 13.3 → Tasks 1/2).
- **Platzhalter-Scan:** Keine TBD/TODO, jeder Code-Block ist vollständig und kompilierbar.
- **Typ-Konsistenz:** `idlePreviewMinutes`/`idlePreviewSeconds`/`idleFraction`/`formattedDisplay`/`setPendingCustomWorkMinutes` werden in Task 1 definiert und in Task 2 mit identischer Signatur verwendet; `TickBarView`s neue Signatur (`fraction:isInteractive:onDrag:`) wird innerhalb von Task 2 definiert und im selben Task/Commit aufgerufen — kein Zwischenzustand, der nicht baut.
- **Bekannte, akzeptierte Einschränkung:** `.numericText(countsDown: true)` animiert beim Hoch-Ziehen im Idle-Zustand weiterhin in "Countdown"-Richtung — kosmetisch, dokumentiert in Task 2, kein Blocker.
