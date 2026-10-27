import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: FocusSession

    var body: some View {
        if session.isRunning {
            ActiveSessionView()
        } else {
            StartView()
        }
    }
}
