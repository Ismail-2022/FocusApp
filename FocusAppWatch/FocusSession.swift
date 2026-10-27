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
        case running(startedAt: Date, endsAt: Date)
        /// Held briefly at full dawn so finishing is a moment rather than a
        /// screen that silently resets. Carries the length actually completed,
        /// extensions included.
        case completed(minutes: Int)
    }

    @Published private(set) var phase: Phase = .idle
    @Published var selectedMinutes: Int = FocusSessionConstants.defaultMinutes

    /// False when the user declined notifications. Surfaced in the UI, because
    /// without them a session that ends in the background reaches nobody.
    @Published private(set) var alertsEnabled = true

    /// Republished every tick so the countdown and the field redraw.
    @Published private(set) var tick = Date()

    private var timer: Timer?
    private var completionReset: Task<Void, Never>?
    private let alerts: SessionAlerting
    private let defaults: UserDefaults

    init(alerts: SessionAlerting = SessionNotifications(),
         defaults: UserDefaults = .standard) {
        self.alerts = alerts
        self.defaults = defaults
        restoreIfNeeded()
        applyDebugLaunchStateIfNeeded()
    }

    /// Lets a simulator launch drop straight into a given state, so screenshots
    /// and screen recordings don't depend on tapping through the flow by hand:
    ///
    ///     xcrun simctl launch <device> <bundle-id> -previewRunning 0.6
    ///     xcrun simctl launch <device> <bundle-id> -previewMinutes 120
    ///
    /// The arguments are the elapsed fraction to pose at, and the session
    /// length to pose with. Debug builds only.
    private func applyDebugLaunchStateIfNeeded() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments

        if let minutesFlag = arguments.firstIndex(of: "-previewMinutes"),
           arguments.indices.contains(minutesFlag + 1),
           let minutes = Int(arguments[minutesFlag + 1]) {
            selectedMinutes = minutes
        }

        guard let flag = arguments.firstIndex(of: "-previewRunning") else { return }

        let fraction = arguments.indices.contains(flag + 1)
            ? Double(arguments[flag + 1]) ?? 0.5
            : 0.5

        let total = Double(selectedMinutes * 60)
        let now = Date()
        phase = .running(startedAt: now.addingTimeInterval(-total * fraction),
                         endsAt: now.addingTimeInterval(total * (1 - fraction)))
        startTicking()
        #endif
    }

    // MARK: - Derived state

    var isRunning: Bool {
        if case .running = phase { return true }
        return false
    }

    var isCompleted: Bool {
        if case .completed = phase { return true }
        return false
    }

    var completedMinutes: Int {
        if case .completed(let minutes) = phase { return minutes }
        return 0
    }

    var remaining: TimeInterval {
        guard case .running(_, let endsAt) = phase else { return 0 }
        return max(0, endsAt.timeIntervalSince(tick))
    }

    var endsAt: Date? {
        guard case .running(_, let endsAt) = phase else { return nil }
        return endsAt
    }

    /// Elapsed fraction of the session, 0...1. Drives the horizon.
    var progress: Double {
        switch phase {
        case .idle:
            return 0
        case .completed:
            return 1
        case .running(let startedAt, let endsAt):
            let total = endsAt.timeIntervalSince(startedAt)
            guard total > 0 else { return 0 }
            return min(max(tick.timeIntervalSince(startedAt) / total, 0), 1)
        }
    }

    // MARK: - Lifecycle

    func prepare() async {
        #if DEBUG
        // Preview launches skip the permission prompt so it doesn't sit on top
        // of whatever state is being captured.
        if ProcessInfo.processInfo.arguments.contains(where: {
            $0 == "-previewRunning" || $0 == "-previewMinutes"
        }) { return }
        #endif

        alertsEnabled = await alerts.requestAuthorization()
    }

    func start() {
        let now = Date()
        begin(startedAt: now,
              endsAt: now.addingTimeInterval(Double(selectedMinutes * 60)))
        WKInterfaceDevice.current().play(.start)
    }

    func extend() {
        guard case .running(let startedAt, let currentEnd) = phase else { return }
        begin(startedAt: startedAt,
              endsAt: currentEnd.addingTimeInterval(Double(FocusSessionConstants.extendMinutes * 60)))
        WKInterfaceDevice.current().play(.click)
    }

    func cancel() {
        teardown()
        phase = .idle
    }

    /// Dismiss the completion screen early.
    func acknowledge() {
        completionReset?.cancel()
        phase = .idle
    }

    // MARK: - Internals

    private func begin(startedAt: Date, endsAt: Date) {
        completionReset?.cancel()
        phase = .running(startedAt: startedAt, endsAt: endsAt)
        defaults.set(startedAt.timeIntervalSince1970, forKey: FocusSessionConstants.persistedStartKey)
        defaults.set(endsAt.timeIntervalSince1970, forKey: FocusSessionConstants.persistedEndKey)

        Task { await alerts.scheduleAlerts(endingAt: endsAt) }
        startTicking()
    }

    /// If the app was terminated mid-session, pick the session back up. The
    /// stored end time is the source of truth, not any in-memory countdown.
    private func restoreIfNeeded() {
        let storedStart = defaults.double(forKey: FocusSessionConstants.persistedStartKey)
        let storedEnd = defaults.double(forKey: FocusSessionConstants.persistedEndKey)
        guard storedStart > 0, storedEnd > 0 else { return }

        let startedAt = Date(timeIntervalSince1970: storedStart)
        let endsAt = Date(timeIntervalSince1970: storedEnd)

        guard endsAt > Date() else {
            // It expired while we were gone. The scheduled alert already fired.
            clearPersisted()
            return
        }

        phase = .running(startedAt: startedAt, endsAt: endsAt)
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
        guard case .running(_, let endsAt) = phase, Date() >= endsAt else { return }
        complete()
    }

    /// Foreground completion only. If the app isn't running when the session
    /// ends, the scheduled notification is what reaches the user instead.
    private func complete() {
        let minutes: Int
        if case .running(let startedAt, let endsAt) = phase {
            minutes = Int((endsAt.timeIntervalSince(startedAt) / 60).rounded())
        } else {
            minutes = selectedMinutes
        }

        teardown()
        phase = .completed(minutes: minutes)
        WKInterfaceDevice.current().play(.success)

        completionReset = Task { [weak self] in
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.phase = .idle }
        }
    }

    private func teardown() {
        timer?.invalidate()
        timer = nil
        completionReset?.cancel()
        clearPersisted()
        alerts.cancelAlerts()
    }

    private func clearPersisted() {
        defaults.removeObject(forKey: FocusSessionConstants.persistedStartKey)
        defaults.removeObject(forKey: FocusSessionConstants.persistedEndKey)
    }
}
