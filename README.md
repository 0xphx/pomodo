# Pomodo

Native macOS-Menüleisten-App für die Pomodoro-Technik. Kein Dock-Icon, läuft ausschließlich in der Menüleiste.

## Setup / Installation

1. [XcodeGen](https://github.com/yonaskolb/XcodeGen) installieren: `brew install xcodegen`
2. Projekt generieren: `xcodegen generate`
3. `Pomodo.xcodeproj` in Xcode öffnen, Scheme "Pomodo", Cmd+R

Voraussetzung: macOS 14 (Sonoma) oder neuer, Xcode 16 oder neuer.

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
