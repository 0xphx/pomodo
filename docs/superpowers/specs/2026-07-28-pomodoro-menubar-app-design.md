# Pomodo — Pomodoro-Menüleisten-App für macOS — Design

Datum: 2026-07-28
Status: Approved (Design), bereit für Implementierungsplan

## 1. Überblick

Native macOS-Menüleisten-App ("Pomodo") für die Pomodoro-Technik. Kein Dock-Icon, kein normales App-Fenster — die App lebt ausschließlich in der Menüleiste (`LSUIElement = true`, SwiftUI `MenuBarExtra`). Der Timer läuft im Hintergrund weiter, unabhängig davon, ob das Dropdown-Panel geöffnet ist.

## 2. Tech-Stack

- Swift + SwiftUI
- **Deployment-Target: macOS 14 (Sonoma) oder neuer** — nötig für die native `.contentTransition(.numericText(countsDown:))`-Ziffernanimation. Der Nutzer fährt durchgehend die jeweils neueste macOS-Version, daher keine Rücksicht auf ältere Systeme nötig.
- Xcode-Projekt, direkt build- und lauffähig
- Keine externen Package-Abhängigkeiten nötig (alles über SwiftUI/AppKit/Foundation-Bordmittel: `MenuBarExtra`, `UNUserNotificationCenter`, `NSSound`, `SMAppService`)

## 3. Architektur

```
Pomodo/
  PomodoApp.swift             App-Entry: MenuBarExtra, Settings-Fenster, LSUIElement
  TimerEngine.swift           ObservableObject, reine Timer-Logik (kein UI)
  Models/
    TimerPhase.swift          enum: .work, .shortBreak, .longBreak
    TimerSettings.swift       ObservableObject, UserDefaults-backed (@AppStorage)
  Views/
    MenuBarLabelView.swift    Custom Label-View für die Menüleiste (Icon / Pill+Countdown)
    MenuBarView.swift         Dropdown-Panel-Inhalt (Root-View des Panels)
    TickBarView.swift         Tick-Fortschrittsleiste (Canvas-basiert)
    ControlsRow.swift         cancel/restart/pause-resume + "..."-Menü
    SettingsView.swift        Separates Einstellungsfenster
  Support/
    SoundPlayer.swift         NSSound-Wrapper für System-Sound-Presets
    NotificationManager.swift UNUserNotificationCenter-Wrapper
    LaunchAtLogin.swift       SMAppService-Wrapper
  PomodoTests/
    TimerEngineTests.swift    XCTest für die Timer-Logik
```

`TimerEngine` ist die einzige Quelle der Wahrheit für den Timer-Zustand. Er wird als `@StateObject` im App-Entry gehalten und per `.environmentObject` an alle Views durchgereicht (Menüleisten-Label, Panel, Settings). Öffnen/Schließen des Panels hat keinen Einfluss auf den laufenden Timer.

## 4. TimerEngine (reine Logik, kein UI)

**Zustand:**
- `phase: TimerPhase` (`.work`, `.shortBreak`, `.longBreak`)
- `remainingSeconds: Int`
- `totalSeconds: Int` (Dauer der aktuellen Phase, für Fortschrittsberechnung)
- `isRunning: Bool`
- `isPaused: Bool`
- `completedWorkCycles: Int` (0–3, zählt Arbeitsphasen seit der letzten langen Pause)

**Zeitberechnung:** Statt Sekunden simpel herunterzuzählen, hält der Engine ein `endDate: Date`. Bei jedem Sekunden-Tick wird `remainingSeconds` aus `endDate.timeIntervalSinceNow` neu berechnet. Das verhindert Drift durch Systemschlaf oder App-Drosselung im Hintergrund.

**Aktionen:**
- `start()` — startet die aktuelle Phase
- `pause()` / `resume()` — pausiert/setzt fort, ohne den Fortschritt zu verlieren
- `restart()` — aktuelle Phase komplett neu von vorn
- `cancel()` — stoppt komplett, Timer zurück auf Ausgangszustand (keine Phase aktiv)
- `skip()` — beendet die aktuelle Phase sofort, löst denselben automatischen Wechsel aus wie ein reguläres Phasenende

**Automatischer Phasenwechsel:**
```
Arbeit → (completedWorkCycles == 4 ? lange Pause, sonst kurze Pause) → Arbeit → ...
```
Der Wechsel erfolgt automatisch und ohne manuellen Eingriff (unattended Flow). Nach einer langen Pause wird `completedWorkCycles` auf 0 zurückgesetzt.

Bei jedem Phasenende: Sound abspielen, System-Notification auslösen, danach automatisch die nächste Phase starten.

## 5. Menüleisten-Anzeige

Custom SwiftUI-View als `MenuBarExtra`-Label (via `MenuBarExtra(content:label:)`), kein Standard-Text/Icon-Label:

- **Idle** (kein Timer aktiv): nur das SF-Symbol-Icon `timer`, normale monochrome Darstellung
- **Läuft / pausiert**: Icon + Countdown-Text zusammen in einem custom dunklen, abgerundeten Pill/Badge (eigener Hintergrund, unabhängig vom System-Hell/Dunkel-Stil der Menüleiste — bewusst kein Standard-Template-Rendering)
- Der Countdown-Text im Pill bekommt dieselbe rollende Ziffern-Animation wie im Panel (siehe unten)

## 6. Dropdown-Panel

Realisiert über `MenuBarExtra` mit `.window`-Style — ein randloses, transientes Fenster (kein Popup-Menü, kein normales App-Fenster), das beim Icon-Klick erscheint/verschwindet.

**Aufbau von oben nach unten:**

1. **Tick-Leiste** (`TickBarView`, `Canvas`-basiert): feste Anzahl dünner vertikaler Striche (60), alle gleich gestylt (kein "erledigt/offen"-Unterschied). Ein einzelner roter Marker wird zusätzlich über das Raster gezeichnet, an Position `elapsedFraction * Breite`. Der Marker bewegt sich stufenlos (per `.animation(.linear(duration: 1), value: elapsedFraction)`), unabhängig von der festen Tick-Anzahl.
2. **Controls-Zeile**: Text-Buttons "cancel", "restart", "pause"/"resume" (Text wechselt je nach `isPaused`); rechts ein "..."-Menü mit: **Einstellungen**, **Skip**, **Beenden**
3. **Zyklus-Indikator**: kleiner visueller Fortschritt (z. B. vier Punkte/Kreise, gefüllt = abgeschlossene Arbeitsphase seit letzter langer Pause)
4. **Große Countdown-Anzeige** unten rechts im Panel, großzügige Typografie, schwarz auf `.ultraThinMaterial`-Hintergrund, mit rollender Ziffern-Animation (`.contentTransition(.numericText(countsDown: true))`)

**Optik:** `.ultraThinMaterial`-Hintergrund, abgerundete Ecken, dezenter Schatten, helles/cleanes UI mit schwarzer Typografie. Sanfte Ein-/Ausblend-Animation beim Öffnen/Schließen des Panels.

## 7. Einstellungsfenster

Separates, echtes Fenster (nicht das Dropdown-Panel), geöffnet über `@Environment(\.openWindow)` (funktioniert zuverlässig auch ohne Dock-Icon/`LSUIElement`).

**Felder:**
- Arbeitsdauer (Default: 25 min)
- Kurze Pausendauer (Default: 5 min)
- Lange Pausendauer (Default: 15 min)
- Zyklen bis lange Pause (Default: 4)
- Sound-Preset (Picker: macOS-Systemsounds — Glass, Ping, Pop, Hero, Submarine)
- Autostart bei Login (Toggle)

**Persistenz:** `TimerSettings` als `ObservableObject` mit `@AppStorage`-Properties, automatisch in UserDefaults gesichert.

## 8. Sound & Notifications

- **Sound:** einmaliger Hinweiston bei Phasenende über `NSSound(named:)`, Preset aus den Einstellungen. Kein wiederholendes/klingelndes Alarmverhalten.
- **Notifications:** `UNUserNotificationCenter`, Berechtigung wird beim ersten App-Start angefragt. Bei Verweigerung läuft die App normal weiter (Sound + Menüleisten-Countdown funktionieren unabhängig davon) — kein Hard-Fail, keine blockierende Fehlermeldung.

## 9. Autostart bei Login

`SMAppService.mainApp.register()` / `.unregister()`, ausgelöst durch den Toggle in den Einstellungen.

## 10. Fehlerbehandlung

- Notification-Berechtigung verweigert → stiller Fallback, kein Blocker
- Sound-Preset nicht abspielbar → Fallback auf Standard-System-Sound
- App-Wachaufwachen nach Systemschlaf → `endDate`-basierte Neuberechnung korrigiert den Countdown automatisch, kein manueller Eingriff nötig

## 11. Testing

- **Unit-Tests (XCTest)** für `TimerEngine`: Phasenübergänge, Long-Break-Zählung nach 4 Zyklen, Verhalten von pause/resume/restart/cancel/skip, `endDate`-basierte Zeitberechnung inkl. simuliertem Zeitsprung
- **UI:** manuelle Verifikation in Xcode (native Mac-App, kein automatisierter Browser/Simulator-Weg verfügbar) — Build & Run, visuelle Prüfung von Panel, Tick-Leiste, Animationen, Menüleisten-Pill

## 12. Out of Scope (bewusst nicht Teil dieser Version)

- Kein wiederholender/klingelnder Alarm-Sound
- Keine Statistik-/Verlaufs-Ansicht vergangener Pomodoro-Sessions
- Keine iCloud-Synchronisation der Einstellungen
- Kein custom (nicht-SF-Symbol) App-Icon in dieser ersten Version — `timer`-SF-Symbol ist leicht austauschbar, sobald ein eigenes Icon gewünscht ist

## 13. Iteration 2 (2026-07-28): Menüleisten-Vereinfachung & interaktive Tick-Leiste

Nach dem ersten Release wurde die App getestet; diese Iteration ändert vier Dinge. Sie **supersediert** die betroffenen Stellen in Abschnitt 5 und 6, der Rest der Spec bleibt gültig.

### 13.1 Menüleisten-Anzeige (supersediert Abschnitt 5)

Kein SF-Symbol-Icon mehr, in keinem Zustand:

- **Idle:** nur Text `"00:00"`, ausgegraut (`.foregroundStyle(.secondary)`), kein Pill-Hintergrund. Zeigt immer literal "00:00" — unabhängig von einer evtl. im Panel eingestellten Vorschau-Dauer (siehe 13.3).
- **Läuft/pausiert:** nur der Countdown-Text, in der dunklen Pille (wie bisher), aber ohne Icon daneben.

### 13.2 "..."-Menü-Button (supersediert den entsprechenden Teil von Abschnitt 6, Punkt 2)

Der bisherige `Text("...")`-Label erzeugt zusammen mit SwiftUIs automatischem Menü-Chevron eine unschöne Doppel-Optik. Neu: Label ist ein expliziter `Image(systemName: "chevron.down")`, zusätzlich `.menuIndicator(.hidden)` gesetzt, damit kein zweiter (automatischer) Chevron dazukommt. Menü-Inhalt (Einstellungen, Skip, Beenden) bleibt unverändert.

### 13.3 Interaktive Tick-Leiste zum Einstellen einer eigenen Dauer (erweitert Abschnitt 6, Punkt 1)

Nur im Idle-Zustand (`!engine.isRunning`) aktiv:

- Die gesamte Tick-Leisten-Fläche ist per Drag-Geste bedienbar (nicht nur der dünne Marker) — Tippen/Ziehen an beliebiger Stelle springt dorthin, klassisches Slider-Verhalten.
- Wertebereich 1–60 Minuten, rastet auf ganze Minuten (60 Ticks ↔ 60 mögliche Minutenwerte, 1:1-Entsprechung: Tick-Index *i* → *i+1* Minuten).
- Gilt **nur einmalig** für die nächste Arbeitsphase, wird nicht in `TimerSettings`/UserDefaults persistiert. Nach `cancel()` oder App-Neustart gilt wieder die konfigurierte Standard-Arbeitsdauer.
- Die große Countdown-Zahl im Panel zeigt im Idle-Zustand live die aktuell gewählte Vorschau-Dauer (Standarddauer aus den Einstellungen, oder die per Drag gewählte) — reagiert damit auch sofort auf Einstellungsänderungen, ohne dass vorher gestartet werden muss.
- Bei Erreichen des rechten Anschlags (60 Min) erscheint ein kleines Stift-Icon neben der Countdown-Zahl. Antippen macht die Zahl zum Inline-Textfeld; Eingabe einer beliebigen Minutenzahl (z. B. "90") + Enter übernimmt diesen Wert als einmalige Sonderdauer (nicht auf 60 begrenzt).

**TimerEngine-Erweiterung:**
- Neue Property `pendingCustomWorkMinutes: Int?`
- Gesetzt durch Drag/Texteingabe (nur sinnvoll im Idle-Zustand)
- Gelöscht bei `cancel()`
- Konsumiert (einmalig verwendet, danach auf `nil` zurückgesetzt) beim `start()` der nächsten Arbeitsphase — nachfolgende automatische Arbeitsphasen (nach Pausen) nutzen wieder `settings.workMinutes`
- Neue berechnete Property für die Idle-Vorschau (Sekunden), z. B. `idlePreviewSeconds: Int { (pendingCustomWorkMinutes ?? settings.workMinutes) * 60 }`, genutzt von `MenuBarView`s großer Countdown-Anzeige und von `TickBarView`s Fraction-Berechnung im Idle-Zustand (`min(idlePreviewSeconds / 3600.0, 1.0)`) — **nicht** von der Menüleisten-Anzeige (die bleibt fix bei "00:00", siehe 13.1).
