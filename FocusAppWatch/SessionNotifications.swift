import Foundation
import UserNotifications

/// Owns the end-of-session alert, deliberately.
///
/// ## Why this exists as its own type
///
/// Two earlier designs for this app died the same way: **a timer owned by a
/// process that can be killed is not a timer.**
///
/// - The Screen Time design (Path B) handed expiry to a system-owned
///   `DeviceActivity` schedule, which is why it would have survived force-quit
///   and reboot. It was blocked for unrelated licensing reasons.
/// - The Shortcuts design (Path A) relied on a `Wait` step inside a running
///   app. When iOS evicted that app from memory, the timer silently died and
///   left the user's phone stuck in Do Not Disturb.
///
/// So this app does not trust an in-app `Timer` to tell the user their session
/// ended. A `Timer` drives the on-screen countdown and nothing else. The alert
/// that actually matters is registered with the system up front, so it fires
/// whether or not this app is still alive when the time comes.
protocol SessionAlerting {
    func requestAuthorization() async
    func scheduleAlerts(endingAt end: Date) async
    func cancelAlerts()
}

final class SessionNotifications: SessionAlerting {

    private let center = UNUserNotificationCenter.current()

    private enum ID {
        static let end = "focus.session.end"
        static let warning = "focus.session.warning"
    }

    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func scheduleAlerts(endingAt end: Date) async {
        cancelAlerts()

        let now = Date()
        let untilEnd = end.timeIntervalSince(now)
        guard untilEnd > 0 else { return }

        await add(
            id: ID.end,
            title: "Session complete",
            body: "Time's up.",
            after: untilEnd
        )

        // Only worth a warning if there's meaningfully more than the warning
        // window left — otherwise it would fire immediately, or after the end.
        let untilWarning = untilEnd - Double(FocusSessionConstants.warningMinutes * 60)
        if untilWarning > 0 {
            await add(
                id: ID.warning,
                title: "\(FocusSessionConstants.warningMinutes) minutes left",
                body: "Nearly there.",
                after: untilWarning
            )
        }
    }

    func cancelAlerts() {
        center.removePendingNotificationRequests(withIdentifiers: [ID.end, ID.warning])
    }

    private func add(id: String, title: String, body: String, after seconds: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        )

        try? await center.add(request)
    }
}
