import Foundation

enum FocusSessionConstants {
    /// Offered session lengths, in minutes.
    static let durations = [15, 25, 45, 60]

    static let defaultMinutes = 25

    /// How much `Extend` adds.
    static let extendMinutes = 10

    /// How long before the end to give the warning haptic.
    static let warningMinutes = 5

    /// Persisted so a session survives the app being terminated mid-run.
    static let persistedStartKey = "focus.session.startedAt"
    static let persistedEndKey = "focus.session.endsAt"
}
