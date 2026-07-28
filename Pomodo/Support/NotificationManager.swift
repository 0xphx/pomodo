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
        let content = self.content(finished: finished, next: next)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request, withCompletionHandler: nil)
    }

    func content(finished: TimerPhase, next: TimerPhase) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title(for: finished)
        content.body = body(for: next)
        return content
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
