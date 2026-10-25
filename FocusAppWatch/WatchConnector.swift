import Foundation
import WatchConnectivity

/// Sends commands to the iPhone. The watch never touches Screen Time itself.
final class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {

    @Published var statusText = "Idle"
    @Published var sessionEnd: Date?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func start(minutes: Int) {
        send(command: .start, minutes: minutes)
    }

    func extend(minutes: Int = FocusSessionConstants.extendMinutes) {
        send(command: .extend, minutes: minutes)
    }

    func end() {
        send(command: .end, minutes: 0)
    }

    private func send(command: FocusMessage.Command, minutes: Int) {
        let payload: [String: Any] = [
            FocusMessage.command: command.rawValue,
            FocusMessage.minutes: minutes
        ]

        // sendMessage is expected to wake the iOS counterpart app in the
        // background if it is not running. THAT IS THE SPIKE'S CLAIM — verify it,
        // and time it. If latency is bad or it fails when the phone is locked,
        // write that down and fall back.
        statusText = "Sending…"
        WCSession.default.sendMessage(payload, replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                let ok = reply[FocusMessage.ok] as? Bool ?? false
                let reason = reply[FocusMessage.reason] as? String ?? ""
                self?.statusText = ok ? "OK" : "Failed: \(reason)"
                if let ts = reply[FocusMessage.endsAt] as? TimeInterval, ts > 0 {
                    self?.sessionEnd = Date(timeIntervalSince1970: ts)
                }
            }
        }, errorHandler: { [weak self] error in
            DispatchQueue.main.async {
                self?.statusText = "Error: \(error.localizedDescription)"
            }
        })
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {}
}
