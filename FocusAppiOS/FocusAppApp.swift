import SwiftUI

@main
struct FocusAppApp: App {
    @StateObject private var session = SessionController()
    @StateObject private var selectionStore = AppSelectionStore()
    @StateObject private var watchReceiver: WatchMessageReceiver

    init() {
        let session = SessionController()
        let store = AppSelectionStore()
        _session = StateObject(wrappedValue: session)
        _selectionStore = StateObject(wrappedValue: store)
        // Activated at launch so the watch can wake the app in the background.
        _watchReceiver = StateObject(wrappedValue: WatchMessageReceiver(session: session,
                                                                       selectionStore: store))
    }

    var body: some Scene {
        WindowGroup {
            SpikeView()
                .environmentObject(session)
                .environmentObject(selectionStore)
        }
    }
}
