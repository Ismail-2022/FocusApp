import DeviceActivity
import ManagedSettings

/// iOS-only. Compiled into BOTH the iOS app and the FocusMonitor extension —
/// if these two disagree, the shield never gets cleared.
extension DeviceActivityName {
    static let focusSession = Self("focusSession")
}

extension ManagedSettingsStore.Name {
    /// A named store keeps FocusApp's shield isolated. Clearing it can never
    /// touch Screen Time settings this app didn't create.
    static let focusSession = Self("focusSession")
}
