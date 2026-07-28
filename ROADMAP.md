# Roadmap

## Geplant
- [ ] Manueller UI-Check der Iteration-2-Änderungen aussteht (Ziehen der Tick-Leiste, Stift-Icon/Texteingabe-Flow inkl. Escape-Abbruch, Single-Chevron-Menü, Light/Dark Mode, Custom-Dauer-dann-Reset-Zyklus) — bisher nur Build/Tests/kein-Dock-Icon programmatisch verifiziert
- [ ] Polish-Nachlese aus dem finalen Code-Review (nicht blockierend, aber offen):
  - `restart()`/`skip()` haben keine konsistenten Idle-Guards
  - `MenuBarLabelView`-Pill bleibt im Dark Mode hartcodiert schwarz (schlecht sichtbar auf dunkler Menüleiste, jetzt umso auffälliger, da die Pille das einzige Element in der Menüleiste ist)
  - Keine Bounds-Validierung für aus UserDefaults gelesene Settings-Werte
  - `PomodoTests`-Target nutzt Swift 5 statt Swift 6 (Konsistenz mit App-Target)
  - Countdown zeigt nie exakt "00:00" (springt direkt zur nächsten Phase)
  - Tick-Leiste pinnt visuell auf 100%, sobald die Settings-Standarddauer ≥60 Min ist (auch ohne Drag) — nur das Stift-Icon-Verhalten wurde dafür korrigiert, nicht die Marker-Darstellung selbst
  - Marker animiert beim Drücken von "start" kurz rückwärts (Idle-Position → 0), kosmetisch
  - Leichtes Layout-Springen der Countdown-Zahl beim Erscheinen/Verschwinden des Stift-Icons an der 60-Min-Grenze
  - Keine Unit-Tests für Drag-Fraction→Minuten-Rundung, Stift-Icon-Schwellenwert-Logik oder `commitCustomDuration`-Parsing/Clamping (als pure Funktionen extrahierbar)

## In Arbeit

## Erledigt
- [x] Pomodoro-Menüleisten-App (Grundgerüst, TimerEngine, UI, Settings, Sound/Notifications) (2026-07-28)
- [x] Menüleisten-Vereinfachung (kein Icon mehr) & interaktive Tick-Leiste mit einmaliger Custom-Dauer (2026-07-28)
