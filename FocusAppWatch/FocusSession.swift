import Foundation
import SwiftUI
import WatchKit

/// Session state and the on-screen countdown.
///
/// The `Timer` here is for *display only*. The alert that tells the user their
/// session is over is registered with the system through `SessionAlerting`, so
/// it survives this object — and this whole app — being terminated. See the
/// comment in `SessionNotifications` for why that distinction is the entire
/// architecture of this app.
@MainActor
final class FocusSession: ObservableObject {

    enum Phase: Equatable {
        case idle
        case running(endsAt: Date)
    }

    @Published private(set) var phase: Phase = .idle
    @Published var selectedMinutes: Int = FocusSessionConstants.defaultMinutes

    /// Republished on every tick purely so the countdown redraws.
    @Published private(set) var tick = Date()

    private var timer: Timer?
    private let alerts: SessionAlerting
    private let defaults: UserDefaults

    init(alerts: SessionAlerting = SessionNotifications(),
         defaults: UserDefaults = .standard) {
        self.alerts = alerts
        self.defaults = defaults
        restoreIfNeeded()
    }

    // MARK: - Derived state

    var isRunning: Bool {
        if case .running = phase { return true }
        return false
    }

    var remaining: TimeInterval {
        guard case .running(let endsAt) = phase else { return 0 }
        return max(0, endsAt.timeIntervalSince(tick))
    }

    var endsAt: Date? {
        guard case .running(let endsAt) = phase else { return nil }
        return endsAt
    }

    // MARK: - Lifecycle

    func prepare() async {
        await alerts.requestAuthorization()
    }

    func start() {
        let end = Date().addingTimeInterval(Double(selectedMinutes * 60))
        begin(endingAt: end)
        WKInterfaceDevice.current().play(.start)
    }

    func extend() {
        guard case .running(let currentEnd) = phase else { return }
        let end = currentEnd.addingTimeInterval(Double(FocusSessionConstants.extendMinutes * 60))
        begin(endingAt: end)
        WKInterfaceDevice.current().play(.click)
    }

    func cancel() {
        finish(playHaptic: false)
    }

    // MARK: - Internals

    private func begin(endingAt end: Date) {
        phase = .running(endsAt: end)
        defaults.set(end.timeIntervalSince1970, forKey: FocusSessionConstants.persistedEndKey)

        Task { await alerts.scheduleAlerts(endingAt: end) }
        startTicking()
    }

    /// If the app was terminated mid-session, pick the session back up. The end
    /// time is the source of truth, not any in-memory countdown.
    private func restoreIfNeeded() {
        let stored = defaults.double(forKey: FocusSessionConstants.persistedEndKey)
        guard stored > 0 else { return }

        let end = Date(timeIntervalSince1970: stored)
        guard end > Date() else {
            // It expired while we were gone. The system alert already fired.
            defaults.removeObject(forKey: FocusSessionConstants.persistedEndKey)
            return
        }

        phase = .running(endsAt: end)
        startTicking()
    }

    private func startTicking() {
        timer?.invalidate()
        tick = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.onTick() }
        }
    }

    private func onTick() {
        tick = Date()
        guard case .running(let endsAt) = phase, Date() >= endsAt else { return }
        // Foreground case only. If the app isn't running, the scheduled
        // notification is what reaches the user instead.
        finish(playHaptic: true)
    }

    private func finish(playHaptic: Bool) {
        timer?.invalidate()
        timer = nil
        phase = .idle
        defaults.removeObject(forKey: FocusSessionConstants.persistedEndKey)
        alerts.cancelAlerts()

        if playHaptic {
            WKInterfaceDevice.current().play(.success)
        }
    }
}
