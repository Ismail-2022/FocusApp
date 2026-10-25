import Foundation

/// Cross-platform constants. MUST NOT import DeviceActivity or ManagedSettings —
/// this file is compiled into the watchOS target, and those frameworks do not
/// exist on watchOS. Anything Screen Time related lives in SharedIOS/.
enum FocusSessionConstants {
    /// DeviceActivitySchedule rejects intervals shorter than this.
    static let minimumSessionMinutes = 15

    /// How long before the end the warning callback should fire.
    static let warningMinutes = 5

    static let defaultSessionMinutes = 25
    static let extendMinutes = 10
}

/// WatchConnectivity message contract. Shared so the watch and the phone
/// cannot drift apart on string keys.
enum FocusMessage {
    static let command = "command"
    static let minutes = "minutes"
    static let ok = "ok"
    static let endsAt = "endsAt"
    static let reason = "reason"

    enum Command: String {
        case start, extend, end
    }
}
