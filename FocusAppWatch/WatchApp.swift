import SwiftUI

@main
struct FocusAppWatchApp: App {
    var body: some Scene {
        WindowGroup {
            // Pointed at the Task 1 verification harness. Restore WatchSpikeView
            // (or delete it) once the backgrounded-haptic question is settled.
            HapticTestView()
        }
    }
}
