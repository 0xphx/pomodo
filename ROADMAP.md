# Roadmap

## Geplant
- [ ] Polish-Nachlese aus dem finalen Code-Review (nicht blockierend, aber offen):
  - Idle-Countdown aktualisiert sich nicht sofort bei Einstellungsänderung
  - `restart()`/`skip()` haben keine konsistenten Idle-Guards
  - `MenuBarLabelView`-Pill bleibt im Dark Mode hartcodiert schwarz (schlecht sichtbar auf dunkler Menüleiste)
  - Keine Bounds-Validierung für aus UserDefaults gelesene Settings-Werte
  - `PomodoTests`-Target nutzt Swift 5 statt Swift 6 (Konsistenz mit App-Target)
  - Countdown zeigt nie exakt "00:00" (springt direkt zur nächsten Phase)

## In Arbeit

## Erledigt
- [x] Pomodoro-Menüleisten-App (Grundgerüst, TimerEngine, UI, Settings, Sound/Notifications) (2026-07-28)
- [x] Menüleisten-Vereinfachung (kein Icon mehr) & interaktive Tick-Leiste mit einmaliger Custom-Dauer (2026-07-28)
