import Foundation

enum FocusSessionConstants {
    /// Offered session lengths, in minutes.
    ///
    /// Fine-grained at the bottom and coarse above it: the difference between
    /// 3 and 4 minutes matters when you're easing in, the difference between
    /// 61 and 62 doesn't. One-minute steps to 10, then fives.
    static let durations: [Int] = Array(1...10) + Array(stride(from: 15, through: 120, by: 5))

    static let defaultMinutes = 25

    /// How much `Extend` adds.
    static let extendMinutes = 10

    /// How long before the end to give the warning haptic.
    static let warningMinutes = 5

    /// Persisted so a session survives the app being terminated mid-run.
    static let persistedStartKey = "focus.session.startedAt"
    static let persistedEndKey = "focus.session.endsAt"
}
