import DeviceActivity
import ManagedSettings

/// THE FAILSAFE.
///
/// This runs in a separate extension process owned by the OS, so it fires even
/// if the main app was force-quit, the phone was rebooted, or the battery died
/// mid-session. It is the only reason Path B is safe to ship.
///
/// Memory budget here is tiny (~6 MB). Do exactly one thing: clear the shield.
/// No logging frameworks, no networking, no extra dependencies. Ever.
class FocusMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore(named: .focusSession)

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Shield is applied by the app at start time. Nothing needed here.
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == .focusSession else { return }

        // Unconditional. If in doubt, unshield.
        store.clearAllSettings()
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        // SPIKE: confirm this fires. If it does, the 5-minute haptic can be
        // triggered from here via a notification rather than an in-app timer.
    }
}
