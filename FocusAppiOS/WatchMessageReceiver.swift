import FamilyControls
import Foundation
import WatchConnectivity

/// The watch is a remote control; all Screen Time logic lives here on iOS
/// (watchOS has no FamilyControls framework).
///
/// SPIKE QUESTION: with this app NOT running, does sendMessage from the watch
/// wake it in the background and start the session? Measure the latency, and
/// test it with the phone locked. If unreliable, sessions start on the phone
/// and the watch becomes display + extend only.
@MainActor
final class WatchMessageReceiver: NSObject, ObservableObject {

    private let session: SessionController
    private let selectionStore: AppSelectionStore

    init(session: SessionController, selectionStore: AppSelectionStore) {
        self.session = session
        self.selectionStore = selectionStore
        super.init()
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    fileprivate func handle(command: String, minutes: Int) -> [String: Any] {
        switch FocusMessage.Command(rawValue: command) {
        case .start:
            guard !selectionStore.isEmpty else {
                return [FocusMessage.ok: false,
                        FocusMessage.reason: "no apps selected — set up on iPhone first"]
            }
            session.start(minutes: minutes, selection: selectionStore.selection)

        case .extend:
            session.extend(byMinutes: minutes, selection: selectionStore.selection)

        case .end:
            session.end()

        case .none:
            return [FocusMessage.ok: false, FocusMessage.reason: "unknown command"]
        }

        return [
            FocusMessage.ok: session.lastError == nil,
            FocusMessage.endsAt: session.sessionEnd?.timeIntervalSince1970 ?? 0,
            FocusMessage.reason: session.lastError ?? ""
        ]
    }
}

extension WatchMessageReceiver: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {}

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any],
                             replyHandler: @escaping ([String: Any]) -> Void) {
        let command = message[FocusMessage.command] as? String ?? ""
        let minutes = message[FocusMessage.minutes] as? Int ?? FocusSessionConstants.defaultSessionMinutes

        Task { @MainActor in
            replyHandler(self.handle(command: command, minutes: minutes))
        }
    }
}
