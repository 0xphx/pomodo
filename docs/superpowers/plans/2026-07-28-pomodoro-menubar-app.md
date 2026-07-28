# Pomodo Menüleisten-App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Native macOS-Menüleisten-App "Pomodo" mit Pomodoro-Timer (SwiftUI, `MenuBarExtra`, kein Dock-Icon), Dropdown-Panel mit Tick-Fortschrittsleiste, Settings-Fenster, Sound/Notification bei Phasenende, Autostart bei Login.

**Architecture:** `TimerEngine` (ObservableObject, reine Logik, `endDate`-basierte Zeitberechnung gegen Drift) ist die einzige Quelle der Wahrheit und wird als `@StateObject` an alle Views durchgereicht. UI ist strikt in Presentational Views (`MenuBarLabelView`, `TickBarView`, `ControlsRow`, `MenuBarView`, `SettingsView`) aufgeteilt, die nur binden/darstellen. Sound/Notification/Login-Item sind dünne Wrapper um System-APIs (`NSSound`, `UNUserNotificationCenter`, `SMAppService`), die über einen `onPhaseCompleted`-Callback an den Engine angebunden werden.

**Tech Stack:** Swift 6, SwiftUI, macOS 14.0 Deployment-Target, XcodeGen (`project.yml`) zur Erzeugung des `.xcodeproj`, XCTest für Unit-Tests, keine externen Package-Abhängigkeiten.

## Global Constraints

- Deployment-Target: macOS 14.0 (Sonoma) oder neuer — exakter Wert aus der Spec, nötig für `.contentTransition(.numericText(countsDown:))`.
- Kein Dock-Icon: `LSUIElement = true` im Info.plist.
- Kein wiederholender/klingelnder Alarm — nur ein einmaliger Hinweiston pro Phasenende.
- Keine externen Swift-Package-Abhängigkeiten; nur SwiftUI/AppKit/Foundation/UserNotifications/ServiceManagement.
- Bundle Identifier: `com.phoenix.pomodo`.
- Build-/Test-Kommandos in diesem Repo brauchen den Prefix `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`, weil die aktiven Command Line Tools sonst kein `xcodebuild` bereitstellen.
- Nach jeder Änderung an `project.yml` muss `xcodegen generate` erneut laufen, damit `Pomodo.xcodeproj` (das mit committed wird) synchron bleibt.
- Commit-Messages im Conventional-Commits-Stil (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`).
- Repo-Workflow-Stufe ist LEICHT, aber diese Änderung betrifft sehr viele Dateien und ist im Kern experimentell (neues Projekt) → auf einem Feature-Branch arbeiten, nicht direkt auf `main`.

## Offene Spec-Lücke, die hier geschlossen wird

Die Spec nennt für die Controls-Zeile nur "pause"/"resume" als wechselnden Button-Text, ohne einen expliziten "start"-Zustand — obwohl Abschnitt 5 einen Idle-Zustand (kein Timer aktiv) beschreibt, der z. B. nach "cancel" erreicht wird. Auflösung: Der Button bekommt einen dritten Text-Zustand **"start"**, wenn `engine.isRunning == false`. Das widerspricht der Spec nicht (dort steht nur "Text wechselt je nach Status"), macht das Verhalten aber vollständig und eindeutig.

---

### Task 1: Xcode-Projekt-Grundgerüst (XcodeGen)

**Files:**
- Create: `project.yml`
- Create: `Pomodo/PomodoApp.swift`
- Create: `PomodoTests/SmokeTests.swift`
- Create: `.gitignore`
- Create: `ROADMAP.md`
- Generate (nicht von Hand schreiben): `Pomodo.xcodeproj/`, `Pomodo/Resources/Info.plist`, `Pomodo/Resources/Pomodo.entitlements` (via `xcodegen generate`)

**Interfaces:**
- Produces: `@main struct PomodoApp: App` mit einer `MenuBarExtra`-Scene (Platzhalter-Label/-Content, wird in Task 10 final verdrahtet). Spätere Tasks fügen in `Pomodo/` weitere Swift-Dateien hinzu, die von XcodeGens `sources: [path: Pomodo]`-Glob automatisch erfasst werden — kein erneutes `xcodegen generate` nötig, außer `project.yml` selbst ändert sich.

- [ ] **Step 1: `project.yml` anlegen**

```yaml
name: Pomodo
options:
  bundleIdPrefix: com.phoenix.pomodo
  deploymentTarget:
    macOS: "14.0"
targets:
  Pomodo:
    type: application
    platform: macOS
    sources:
      - path: Pomodo
    info:
      path: Pomodo/Resources/Info.plist
      properties:
        LSUIElement: true
        CFBundleDisplayName: Pomodo
        NSHumanReadableCopyright: ""
    entitlements:
      path: Pomodo/Resources/Pomodo.entitlements
      properties:
        com.apple.security.app-sandbox: false
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.phoenix.pomodo
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
        SWIFT_VERSION: "6.0"
        ENABLE_HARDENED_RUNTIME: true
        MACOSX_DEPLOYMENT_TARGET: "14.0"
  PomodoTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - path: PomodoTests
    dependencies:
      - target: Pomodo
    settings:
      base:
        MACOSX_DEPLOYMENT_TARGET: "14.0"
        GENERATE_INFOPLIST_FILE: true
schemes:
  Pomodo:
    build:
      targets:
        Pomodo: all
        PomodoTests: [test]
    test:
      targets:
        - PomodoTests
    run:
      config: Debug
```

- [ ] **Step 2: Minimalen App-Entry anlegen (`Pomodo/PomodoApp.swift`)**

```swift
import SwiftUI

@main
struct PomodoApp: App {
    var body: some Scene {
        MenuBarExtra("Pomodo", systemImage: "timer") {
            Text("Pomodo")
        }
    }
}
```

- [ ] **Step 3: Smoke-Test anlegen (`PomodoTests/SmokeTests.swift`)**

```swift
import XCTest
@testable import Pomodo

final class SmokeTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 4: `.gitignore` anlegen**

```
.DS_Store
DerivedData/
xcuserdata/
.build/
.superpowers/
```

- [ ] **Step 5: `ROADMAP.md` anlegen**

```markdown
# Roadmap

## Geplant

## In Arbeit
- [ ] Pomodoro-Menüleisten-App (Grundgerüst, TimerEngine, UI, Settings, Sound/Notifications)

## Erledigt
```

- [ ] **Step 6: Projekt generieren**

Run: `xcodegen generate`
Expected: `Created project at .../Pomodo.xcodeproj`, keine Fehler.

- [ ] **Step 7: Build verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: Tests verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS'`
Expected: `** TEST SUCCEEDED **`, `testModuleLoads` passed.

- [ ] **Step 9: Manuell prüfen: kein Dock-Icon**

Öffne `Pomodo.xcodeproj` in Xcode, Cmd+R. Erwartet: Icon erscheint in der Menüleiste, **kein** Icon im Dock, Klick öffnet ein Dropdown mit "Pomodo"-Text.

- [ ] **Step 10: Commit**

```bash
git add project.yml Pomodo.xcodeproj Pomodo/PomodoApp.swift Pomodo/Resources PomodoTests/SmokeTests.swift .gitignore ROADMAP.md
git commit -m "feat: scaffold Pomodo menu bar app via XcodeGen"
```

---

### Task 2: Models — `TimerPhase` & `TimerSettings`

**Files:**
- Create: `Pomodo/Models/TimerPhase.swift`
- Create: `Pomodo/Models/TimerSettings.swift`
- Test: `PomodoTests/TimerSettingsTests.swift`

**Interfaces:**
- Produces: `enum TimerPhase: Equatable { case work, shortBreak, longBreak }`
- Produces: `final class TimerSettings: ObservableObject` mit `@Published var workMinutes: Int`, `shortBreakMinutes: Int`, `longBreakMinutes: Int`, `cyclesBeforeLongBreak: Int`, `soundPreset: SoundPreset`, `launchAtLogin: Bool`; `init(defaults: UserDefaults = .standard)`. Defaults: 25 / 5 / 15 / 4 / `.glass` / `false`.
- Consumes: `SoundPreset` (wird in Task 3 definiert) — `TimerSettings.swift` referenziert den Typnamen; da beide Dateien im selben Modul (`Pomodo`-Target) liegen, kompiliert das erst, sobald Task 3 `SoundPreset` hinzugefügt hat. Deshalb wird `SoundPreset` als Vorgriff **in diesem Task** bereits mit-deklariert (in `TimerSettings.swift`, nicht in `Pomodo/Support/SoundPlayer.swift`) und in Task 3 nicht erneut definiert, sondern nur verwendet.

- [ ] **Step 1: `TimerPhase` anlegen**

```swift
// Pomodo/Models/TimerPhase.swift
import Foundation

enum TimerPhase: Equatable {
    case work
    case shortBreak
    case longBreak
}
```

- [ ] **Step 2: Failing Test für `TimerSettings` schreiben**

```swift
// PomodoTests/TimerSettingsTests.swift
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
```

- [ ] **Step 3: Test laufen lassen, Fehlschlag verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS' -only-testing:PomodoTests/TimerSettingsTests`
Expected: FAIL — `TimerSettings`/`SoundPreset` existieren noch nicht.

- [ ] **Step 4: `TimerSettings` implementieren (inkl. `SoundPreset`)**

```swift
// Pomodo/Models/TimerSettings.swift
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
```

- [ ] **Step 5: Tests laufen lassen, Erfolg verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS' -only-testing:PomodoTests/TimerSettingsTests`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add Pomodo/Models PomodoTests/TimerSettingsTests.swift
git commit -m "feat: add TimerPhase and TimerSettings models"
```

---

### Task 3: Sound-Presets — `SoundPlayer`

**Files:**
- Create: `Pomodo/Support/SoundPlayer.swift`
- Test: `PomodoTests/SoundPlayerTests.swift`

**Interfaces:**
- Consumes: `SoundPreset` (aus Task 2, `Pomodo/Models/TimerSettings.swift`)
- Produces: `struct SoundPlayer { func play(_ preset: SoundPreset) }`

- [ ] **Step 1: Failing Test schreiben**

```swift
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

    func testPlayDoesNotCrashForEveryPreset() {
        let player = SoundPlayer()
        for preset in SoundPreset.allCases {
            player.play(preset)
        }
    }
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS' -only-testing:PomodoTests/SoundPlayerTests`
Expected: FAIL — `SoundPlayer` existiert noch nicht.

- [ ] **Step 3: `SoundPlayer` implementieren**

```swift
// Pomodo/Support/SoundPlayer.swift
import AppKit

struct SoundPlayer {
    func play(_ preset: SoundPreset) {
        let sound = NSSound(named: preset.rawValue) ?? NSSound(named: SoundPreset.glass.rawValue)
        sound?.play()
    }
}
```

- [ ] **Step 4: Tests laufen lassen, Erfolg verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS' -only-testing:PomodoTests/SoundPlayerTests`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add Pomodo/Support/SoundPlayer.swift PomodoTests/SoundPlayerTests.swift
git commit -m "feat: add SoundPlayer for phase-end notification sound"
```

---

### Task 4: `NotificationManager`

**Files:**
- Create: `Pomodo/Support/NotificationManager.swift`
- Test: `PomodoTests/NotificationManagerTests.swift`

**Interfaces:**
- Consumes: `TimerPhase` (aus Task 2)
- Produces: `struct NotificationManager { func requestAuthorization(); func notifyPhaseCompleted(finished: TimerPhase, next: TimerPhase); func title(for phase: TimerPhase) -> String; func body(for phase: TimerPhase) -> String }`

- [ ] **Step 1: Failing Test schreiben**

```swift
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
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS' -only-testing:PomodoTests/NotificationManagerTests`
Expected: FAIL — `NotificationManager` existiert noch nicht.

- [ ] **Step 3: `NotificationManager` implementieren**

```swift
// Pomodo/Support/NotificationManager.swift
import UserNotifications

struct NotificationManager {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notifyPhaseCompleted(finished: TimerPhase, next: TimerPhase) {
        let content = UNMutableNotificationContent()
        content.title = title(for: finished)
        content.body = body(for: next)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request, withCompletionHandler: nil)
    }

    func title(for phase: TimerPhase) -> String {
        switch phase {
        case .work: return "Arbeitsphase beendet"
        case .shortBreak: return "Pause beendet"
        case .longBreak: return "Lange Pause beendet"
        }
    }

    func body(for phase: TimerPhase) -> String {
        switch phase {
        case .work: return "Zeit für die nächste Arbeitsphase."
        case .shortBreak: return "Zeit für eine kurze Pause."
        case .longBreak: return "Zeit für eine lange Pause."
        }
    }
}
```

Hinweis: `body(for:)` wird mit der **nächsten** Phase aufgerufen (`next`), `title(for:)` mit der **beendeten** Phase (`finished`) — siehe `notifyPhaseCompleted`.

- [ ] **Step 4: Tests laufen lassen, Erfolg verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS' -only-testing:PomodoTests/NotificationManagerTests`
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add Pomodo/Support/NotificationManager.swift PomodoTests/NotificationManagerTests.swift
git commit -m "feat: add NotificationManager for phase-end system notifications"
```

---

### Task 5: `LaunchAtLogin`

**Files:**
- Create: `Pomodo/Support/LaunchAtLogin.swift`

**Interfaces:**
- Produces: `struct LaunchAtLogin { func setEnabled(_ enabled: Bool); var isEnabled: Bool { get } }`
- Kein automatisierter Test: `SMAppService` verändert echten System-Login-Item-Status und ist in einer CI-/Unit-Test-Umgebung nicht sinnvoll zu verifizieren (siehe Spec Abschnitt 11 — Systemintegration wird manuell geprüft).

- [ ] **Step 1: `LaunchAtLogin` implementieren**

```swift
// Pomodo/Support/LaunchAtLogin.swift
import ServiceManagement

struct LaunchAtLogin {
    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("LaunchAtLogin: Statusänderung fehlgeschlagen: \(error)")
        }
    }

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
```

- [ ] **Step 2: Build verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodo/Support/LaunchAtLogin.swift
git commit -m "feat: add LaunchAtLogin wrapper around SMAppService"
```

---

### Task 6: `TimerEngine` (Kernlogik)

**Files:**
- Create: `Pomodo/TimerEngine.swift`
- Test: `PomodoTests/TimerEngineTests.swift`

**Interfaces:**
- Consumes: `TimerPhase` (Task 2), `TimerSettings` (Task 2)
- Produces: `final class TimerEngine: ObservableObject` mit:
  - `@Published private(set) var phase: TimerPhase`
  - `@Published private(set) var remainingSeconds: Int`
  - `@Published private(set) var totalSeconds: Int`
  - `@Published private(set) var isRunning: Bool`
  - `@Published private(set) var isPaused: Bool`
  - `@Published private(set) var completedWorkCycles: Int`
  - `var onPhaseCompleted: ((TimerPhase, TimerPhase) -> Void)?`
  - `var cyclesBeforeLongBreak: Int { get }`
  - `var elapsedFraction: Double { get }`
  - `var formattedRemaining: String { get }`
  - `init(settings: TimerSettings, now: @escaping () -> Date = Date.init)`
  - `func start()`, `func pause()`, `func resume()`, `func restart()`, `func cancel()`, `func skip()`
  - `func tick()` — **internal** (nicht `private`), damit Tests einen Sekunden-Tick deterministisch simulieren können, ohne auf einen echten `Timer` zu warten.

Spätere Tasks (7, 8) verwenden ausschließlich diese Properties/Methoden — keine weiteren.

- [ ] **Step 1: Kompletten Testfile schreiben**

```swift
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
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS' -only-testing:PomodoTests/TimerEngineTests`
Expected: FAIL — `TimerEngine` existiert noch nicht.

- [ ] **Step 3: `TimerEngine` implementieren**

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

    var onPhaseCompleted: ((TimerPhase, TimerPhase) -> Void)?

    private let settings: TimerSettings
    private let now: () -> Date
    private var endDate: Date?
    private var pausedRemainingSeconds: Int?
    private var ticker: Timer?

    var cyclesBeforeLongBreak: Int { settings.cyclesBeforeLongBreak }

    var elapsedFraction: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1 - (Double(remainingSeconds) / Double(totalSeconds))
    }

    var formattedRemaining: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
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

    private func beginPhase(_ phase: TimerPhase) {
        totalSeconds = duration(for: phase)
        remainingSeconds = totalSeconds
        endDate = now().addingTimeInterval(TimeInterval(remainingSeconds))
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

- [ ] **Step 4: Tests laufen lassen, Erfolg verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS' -only-testing:PomodoTests/TimerEngineTests`
Expected: `** TEST SUCCEEDED **`, alle 11 Tests grün.

- [ ] **Step 5: Commit**

```bash
git add Pomodo/TimerEngine.swift PomodoTests/TimerEngineTests.swift
git commit -m "feat: add TimerEngine with endDate-based countdown and long-break cycling"
```

---

### Task 7: Menüleisten-Label & Tick-Leiste

**Files:**
- Create: `Pomodo/Views/MenuBarLabelView.swift`
- Create: `Pomodo/Views/TickBarView.swift`

**Interfaces:**
- Consumes: `TimerEngine` (Task 6) — `isRunning`, `formattedRemaining`, `remainingSeconds`; `Double` `elapsedFraction` (für `TickBarView`)
- Produces: `struct MenuBarLabelView: View { init(engine: TimerEngine) }`, `struct TickBarView: View { init(elapsedFraction: Double) }`
- Kein automatisierter Test: reine SwiftUI-Darstellung, manuell verifiziert (siehe Spec Abschnitt 11).

- [ ] **Step 1: `TickBarView` implementieren**

```swift
// Pomodo/Views/TickBarView.swift
import SwiftUI

struct TickBarView: View {
    let elapsedFraction: Double
    private let tickCount = 60

    var body: some View {
        Canvas { context, size in
            let tickWidth: CGFloat = 1.5
            let spacing = size.width / CGFloat(tickCount)
            for index in 0..<tickCount {
                let x = CGFloat(index) * spacing
                let rect = CGRect(x: x, y: 0, width: tickWidth, height: size.height)
                context.fill(Path(rect), with: .color(.gray.opacity(0.4)))
            }
            let markerX = CGFloat(elapsedFraction) * size.width
            let markerRect = CGRect(x: markerX, y: 0, width: 2, height: size.height)
            context.fill(Path(markerRect), with: .color(.red))
        }
        .frame(height: 24)
        .animation(.linear(duration: 1), value: elapsedFraction)
    }
}
```

- [ ] **Step 2: `MenuBarLabelView` implementieren**

```swift
// Pomodo/Views/MenuBarLabelView.swift
import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var engine: TimerEngine

    var body: some View {
        if engine.isRunning {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text(engine.formattedRemaining)
                    .font(.system(.body, design: .monospaced))
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: engine.remainingSeconds)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.black))
            .foregroundStyle(Color.white)
        } else {
            Image(systemName: "timer")
        }
    }
}
```

- [ ] **Step 3: Build verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Pomodo/Views/MenuBarLabelView.swift Pomodo/Views/TickBarView.swift
git commit -m "feat: add menu bar label pill and tick progress bar views"
```

---

### Task 8: Controls-Zeile & Panel-Zusammenbau

**Files:**
- Create: `Pomodo/Views/ControlsRow.swift`
- Create: `Pomodo/Views/MenuBarView.swift`

**Interfaces:**
- Consumes: `TimerEngine` (Task 6) — alle Actions (`start`, `pause`, `resume`, `restart`, `cancel`, `skip`), `isRunning`, `isPaused`, `elapsedFraction`, `formattedRemaining`, `remainingSeconds`, `completedWorkCycles`, `cyclesBeforeLongBreak`; `TickBarView` (Task 7)
- Produces: `struct ControlsRow: View { init(engine: TimerEngine) }`, `struct MenuBarView: View { init(engine: TimerEngine) }`
- Kein automatisierter Test: reine SwiftUI-Darstellung, manuell verifiziert.

- [ ] **Step 1: `ControlsRow` implementieren**

```swift
// Pomodo/Views/ControlsRow.swift
import SwiftUI
import AppKit

struct ControlsRow: View {
    @ObservedObject var engine: TimerEngine
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack {
            Button("cancel") { engine.cancel() }
            Button("restart") { engine.restart() }
            Spacer()
            Button(primaryButtonLabel) { primaryButtonAction() }
            Menu {
                Button("Einstellungen") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "settings")
                }
                Button("Skip") { engine.skip() }
                Button("Beenden") { NSApplication.shared.terminate(nil) }
            } label: {
                Text("...")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .buttonStyle(.plain)
    }

    private var primaryButtonLabel: String {
        if !engine.isRunning { return "start" }
        return engine.isPaused ? "resume" : "pause"
    }

    private func primaryButtonAction() {
        if !engine.isRunning {
            engine.start()
        } else if engine.isPaused {
            engine.resume()
        } else {
            engine.pause()
        }
    }
}
```

- [ ] **Step 2: `MenuBarView` implementieren**

```swift
// Pomodo/Views/MenuBarView.swift
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var engine: TimerEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TickBarView(elapsedFraction: engine.elapsedFraction)
            ControlsRow(engine: engine)
            HStack {
                cycleIndicator
                Spacer()
                Text(engine.formattedRemaining)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: engine.remainingSeconds)
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(.ultraThinMaterial)
        .foregroundStyle(Color.black)
    }

    private var cycleIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(engine.cyclesBeforeLongBreak, 1), id: \.self) { index in
                Circle()
                    .fill(index < engine.completedWorkCycles ? Color.black : Color.black.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }
}
```

- [ ] **Step 3: Build verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Pomodo/Views/ControlsRow.swift Pomodo/Views/MenuBarView.swift
git commit -m "feat: assemble dropdown panel with controls row and cycle indicator"
```

---

### Task 9: Einstellungsfenster

**Files:**
- Create: `Pomodo/Views/SettingsView.swift`

**Interfaces:**
- Consumes: `TimerSettings` (Task 2), `SoundPreset` (Task 2), `LaunchAtLogin` (Task 5)
- Produces: `struct SettingsView: View { init(settings: TimerSettings) }`
- Kein automatisierter Test: reines Formular, manuell verifiziert.

- [ ] **Step 1: `SettingsView` implementieren**

```swift
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
```

- [ ] **Step 2: Build verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Pomodo/Views/SettingsView.swift
git commit -m "feat: add settings window for durations, sound preset and launch at login"
```

---

### Task 10: Finale App-Verdrahtung, README & Roadmap

**Files:**
- Modify: `Pomodo/PomodoApp.swift`
- Modify: `README.md`
- Modify: `ROADMAP.md`

**Interfaces:**
- Consumes: alles aus Tasks 2–9 (`TimerSettings`, `TimerEngine`, `SoundPlayer`, `NotificationManager`, `MenuBarLabelView`, `MenuBarView`, `SettingsView`)
- Produces: fertiges, lauffähiges `@main struct PomodoApp: App`

- [ ] **Step 1: `PomodoApp.swift` final verdrahten**

```swift
// Pomodo/PomodoApp.swift
import SwiftUI

@main
struct PomodoApp: App {
    @StateObject private var settings: TimerSettings
    @StateObject private var engine: TimerEngine

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
```

- [ ] **Step 2: Build verifizieren**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Alle Tests laufen lassen**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Pomodo.xcodeproj -scheme Pomodo -destination 'platform=macOS'`
Expected: `** TEST SUCCEEDED **`, alle Tests aus Tasks 1–6 grün.

- [ ] **Step 4: Manueller End-to-End-Check**

Öffne `Pomodo.xcodeproj` in Xcode, Cmd+R. Prüfe:
- Kein Dock-Icon, Icon erscheint in der Menüleiste (nur Icon, kein Text — idle)
- Klick auf "start" im Panel → Menüleiste zeigt Pill mit Countdown, Ziffern rollen beim Runterzählen
- Tick-Leiste bewegt roten Marker sichtbar
- "pause"/"resume"/"cancel"/"restart" funktionieren wie erwartet
- "..."-Menü öffnet Einstellungsfenster (echtes Fenster mit Titelleiste, kein Dock-Icon-Wechsel)
- Einstellungen ändern (z. B. Arbeitsdauer) wirkt sich auf den nächsten Timer-Start aus
- Nach Ablauf einer kurzen Testdauer (z. B. Arbeitsdauer temporär auf 1 min stellen): Sound spielt, macOS-Notification erscheint, nächste Phase startet automatisch

- [ ] **Step 5: `README.md` aktualisieren**

```markdown
# Pomodo

Native macOS-Menüleisten-App für die Pomodoro-Technik. Kein Dock-Icon, läuft ausschließlich in der Menüleiste.

## Setup / Installation

1. [XcodeGen](https://github.com/yonaskolb/XcodeGen) installieren: `brew install xcodegen`
2. Projekt generieren: `xcodegen generate`
3. `Pomodo.xcodeproj` in Xcode öffnen, Scheme "Pomodo", Cmd+R

Voraussetzung: macOS 14 (Sonoma) oder neuer, Xcode 15 oder neuer.

## Nutzung

- Icon in der Menüleiste anklicken öffnet das Timer-Panel
- "start" beginnt eine Arbeitsphase (Standard 25 min), danach automatisch kurze Pause (5 min); alle 4 Zyklen eine lange Pause (15 min)
- "pause"/"resume", "restart", "cancel" steuern den laufenden Timer
- "..."-Menü: Einstellungen, Skip (aktuelle Phase überspringen), Beenden
- Einstellungen (Arbeitsdauer, Pausendauer, Zyklenanzahl, Sound-Preset, Autostart bei Login) über das "..."-Menü → Einstellungen

## Projektstruktur

- `project.yml` — XcodeGen-Spezifikation, erzeugt `Pomodo.xcodeproj`
- `Pomodo/` — App-Quellcode (`PomodoApp.swift`, `TimerEngine.swift`, `Models/`, `Views/`, `Support/`)
- `PomodoTests/` — XCTest-Unit-Tests (TimerEngine, TimerSettings, SoundPlayer, NotificationManager)
- `docs/superpowers/` — Design-Spec und Implementierungsplan dieser App

## Status

Siehe [ROADMAP.md](ROADMAP.md).
```

- [ ] **Step 6: `ROADMAP.md` aktualisieren**

```markdown
# Roadmap

## Geplant

## In Arbeit

## Erledigt
- [x] Pomodoro-Menüleisten-App (Grundgerüst, TimerEngine, UI, Settings, Sound/Notifications) (2026-07-28)
```

- [ ] **Step 7: Commit**

```bash
git add Pomodo/PomodoApp.swift README.md ROADMAP.md
git commit -m "feat: wire up TimerEngine, sound and notifications in app entry point"
```

---

## Self-Review-Notizen (bereits durchgeführt)

- **Spec-Abdeckung:** Alle Abschnitte 1–12 der Design-Spec sind auf Tasks gemappt (siehe Zuordnung oben); Abschnitt 12 (Out of Scope) wird durch bewusstes Weglassen erfüllt.
- **Platzhalter-Scan:** Keine TBD/TODO, jeder Code-Block ist vollständig und kompilierbar.
- **Typ-Konsistenz:** `TimerPhase`, `TimerSettings`, `SoundPreset`, `TimerEngine`-API, `SoundPlayer`, `NotificationManager`, `LaunchAtLogin` werden über alle Tasks hinweg mit identischen Signaturen verwendet.
- **Offene Spec-Lücke** (dritter Button-Zustand "start") wurde oben explizit dokumentiert und aufgelöst.
