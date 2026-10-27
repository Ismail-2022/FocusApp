import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: FocusSession

    var body: some View {
        ZStack {
            Palette.void
                .ignoresSafeArea()

            HorizonField(progress: session.progress)

            switch session.phase {
            case .idle:
                StartView()
                    .transition(.opacity)
            case .running:
                ActiveSessionView()
                    .transition(.opacity)
            case .completed:
                CompletedView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: session.isRunning)
        .animation(.easeInOut(duration: 0.35), value: session.isCompleted)
    }
}
