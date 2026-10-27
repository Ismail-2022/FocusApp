import SwiftUI
import UserNotifications

@main
struct FocusAppWatchApp: App {
    @StateObject private var session = FocusSession()
    private let foregroundPresenter = ForegroundPresenter()

    init() {
        // Without this, a notification that fires while the app is open is
        // suppressed — the user would get nothing at all in the one case where
        // they're actually looking at the app.
        UNUserNotificationCenter.current().delegate = foregroundPresenter
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .task { await session.prepare() }
        }
    }
}

/// Lets scheduled alerts still present while the app is foregrounded.
final class ForegroundPresenter: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
