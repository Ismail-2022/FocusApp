import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import os

/// The one thing that differs between a real build and a demo build.
///
/// Everything above this protocol (SessionController, the UI, the watch bridge)
/// is identical in both modes — so Demo Mode exercises the real code paths, not
/// a parallel fake app. That's the whole point.
@MainActor
protocol ShieldBackend: AnyObject {
    var isDemo: Bool { get }
    var onExpiry: (() -> Void)? { get set }

    func apply(selection: FamilyActivitySelection)
    func clear()
    func scheduleExpiry(from start: Date, to end: Date) throws
    func cancelExpiry()
}

// MARK: - Real

/// Requires: paid Apple Developer membership, the Family Controls entitlement,
/// and a physical device. Expiry is owned by the OS, not by this process.
@MainActor
final class RealShieldBackend: ShieldBackend {
    let isDemo = false
    var onExpiry: (() -> Void)?

    private let store = ManagedSettingsStore(named: .focusSession)
    private let center = DeviceActivityCenter()

    func apply(selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil : .specific(selection.categoryTokens)
    }

    func clear() {
        store.clearAllSettings()
    }

    func scheduleExpiry(from start: Date, to end: Date) throws {
        let calendar = Calendar.current
        let parts: Set<Calendar.Component> = [.hour, .minute, .second]

        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(parts, from: start),
            intervalEnd: calendar.dateComponents(parts, from: end),
            repeats: false,
            warningTime: DateComponents(minute: FocusSessionConstants.warningMinutes)
        )

        try center.startMonitoring(.focusSession, during: schedule)
    }

    func cancelExpiry() {
        center.stopMonitoring([.focusSession])
    }
}

// MARK: - Demo

/// Runs anywhere: simulator, no entitlement, no paid account, no Apple Watch.
/// Logs what it *would* have shielded and owns its own expiry timer.
///
/// Honest about itself — `isDemo` is surfaced in the UI so nobody is ever
/// fooled into thinking apps are really being blocked.
@MainActor
final class DemoShieldBackend: ShieldBackend {
    let isDemo = true
    var onExpiry: (() -> Void)?

    private let log = Logger(subsystem: "com.ismail.focusapp", category: "demo")
    private var expiryTask: Task<Void, Never>?

    func apply(selection: FamilyActivitySelection) {
        log.info("DEMO: would shield \(selection.applicationTokens.count) apps, \(selection.categoryTokens.count) categories")
    }

    func clear() {
        log.info("DEMO: shield cleared")
    }

    func scheduleExpiry(from start: Date, to end: Date) throws {
        // Deliberately skips the real 15-minute minimum so the demo (and CI)
        // can run a short session. Noted in the README so it isn't mistaken
        // for the real constraint.
        let seconds = max(1, end.timeIntervalSince(start))
        log.info("DEMO: expiry in \(seconds)s")

        expiryTask?.cancel()
        expiryTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.log.info("DEMO: interval ended, clearing")
                self?.onExpiry?()
            }
        }
    }

    func cancelExpiry() {
        expiryTask?.cancel()
        expiryTask = nil
    }
}

// MARK: - Selection

enum ShieldBackendFactory {
    @MainActor
    static func make() -> ShieldBackend {
        #if DEMO_MODE
        return DemoShieldBackend()
        #else
        return RealShieldBackend()
        #endif
    }
}
