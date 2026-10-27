import SwiftUI
import UserNotifications
import WatchKit

/// VERIFICATION HARNESS — not product code. Delete once Task 1's open question
/// is answered.
///
/// The question: **does an end-of-session haptic reliably fire when the watch app
/// is backgrounded or terminated?**
///
/// This matters because both previous spikes died the same way — a timer owned by
/// a process that can be killed is not a timer. Path B solved it with an OS-owned
/// DeviceActivity schedule; Path A had no equivalent and failed. Path C must not
/// repeat that, so the end-of-session haptic has to come from something the system
/// owns: a scheduled local notification.
///
/// An in-app Timer is tested here too, purely to demonstrate the contrast.
@MainActor
final class HapticTest: ObservableObject {
    @Published var status = "Not authorized yet"
    @Published var log: [String] = []

    private var inAppTimer: Timer?

    private var now: String {
        Date().formatted(date: .omitted, time: .standard)
    }

    private func note(_ message: String) {
        log.insert("\(now) — \(message)", at: 0)
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            status = granted ? "Authorized" : "DENIED — notifications won't fire"
            note("authorization: \(granted ? "granted" : "denied")")
        } catch {
            status = "Error: \(error.localizedDescription)"
            note("authorization error: \(error.localizedDescription)")
        }
    }

    // MARK: - Test 1: system-scheduled local notification

    /// THE IMPORTANT TEST. Schedule, then background the app with the Digital
    /// Crown (or let the screen sleep) and leave it alone.
    func scheduleNotification(seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Focus session complete"
        content.body = "Scheduled at \(now) for +\(Int(seconds))s"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "haptic-test-\(Int(seconds))",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            Task { @MainActor in
                if let error {
                    self?.note("schedule FAILED: \(error.localizedDescription)")
                } else {
                    self?.note("notification scheduled for +\(Int(seconds))s")
                }
            }
        }
    }

    // MARK: - Test 2: in-app timer (expected to fail when backgrounded)

    /// Included as the control case. If this fires but the notification doesn't,
    /// the conclusion is the opposite of what we expect — write that down.
    func startInAppTimer(seconds: TimeInterval) {
        inAppTimer?.invalidate()
        note("in-app Timer started for +\(Int(seconds))s")
        inAppTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                WKInterfaceDevice.current().play(.notification)
                self?.note("in-app Timer FIRED")
            }
        }
    }

    // MARK: - Test 3: does the haptic hardware work at all

    func playHapticNow() {
        WKInterfaceDevice.current().play(.notification)
        note("played .notification haptic directly")
    }

    func clearPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        inAppTimer?.invalidate()
        note("cleared all pending")
    }
}

struct HapticTestView: View {
    @StateObject private var test = HapticTest()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(test.status)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Button("1. Authorize") {
                        Task { await test.requestAuthorization() }
                    }

                    Divider()

                    Text("Notification (system-owned)")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Button("Schedule +60s") { test.scheduleNotification(seconds: 60) }
                    Button("Schedule +5 min") { test.scheduleNotification(seconds: 300) }

                    Divider()

                    Text("In-app Timer (control)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Button("Timer +60s") { test.startInAppTimer(seconds: 60) }

                    Divider()

                    Button("Haptic now") { test.playHapticNow() }
                    Button("Clear pending", role: .destructive) { test.clearPending() }

                    Divider()

                    Text("Log")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ForEach(test.log, id: \.self) { line in
                        Text(line)
                            .font(.system(size: 10, design: .monospaced))
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("Haptic Test")
        }
    }
}
