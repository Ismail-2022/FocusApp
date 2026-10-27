import FamilyControls
import Foundation

/// UI-facing session state. Identical code in demo and real builds.
///
/// Safety rule baked in: a shield must never exist without an expiry owner.
/// If scheduling fails at any point, the shield comes down immediately.
/// Fail closed, always.
@MainActor
final class SessionController: ObservableObject {
    @Published private(set) var sessionEnd: Date?
    @Published private(set) var lastError: String?

    private let backend: ShieldBackend

    var isDemo: Bool { backend.isDemo }

    var isActive: Bool {
        guard let sessionEnd else { return false }
        return sessionEnd > Date()
    }

    init(backend: ShieldBackend? = nil) {
        // NOTE: can't default `backend` directly to `ShieldBackendFactory.make()` —
        // default-parameter expressions evaluate in a nonisolated context even
        // when the initializer itself is @MainActor, so the compiler rejects
        // calling a @MainActor factory there. Resolving it in the body instead.
        self.backend = backend ?? ShieldBackendFactory.make()
        self.backend.onExpiry = { [weak self] in
            self?.backend.clear()
            self?.sessionEnd = nil
        }
    }

    func start(minutes: Int, selection: FamilyActivitySelection) {
        let now = Date()
        guard let end = Calendar.current.date(byAdding: .minute, value: minutes, to: now) else { return }

        backend.apply(selection: selection)

        do {
            try backend.scheduleExpiry(from: now, to: end)
            sessionEnd = end
            lastError = nil
        } catch {
            // No failsafe means no shield.
            backend.clear()
            sessionEnd = nil
            lastError = "Could not schedule expiry — shield removed: \(error)"
        }
    }

    /// SPIKE QUESTION: if the new window is under 15 minutes, does the real
    /// backend throw here? Record the answer in the findings log.
    func extend(byMinutes minutes: Int, selection: FamilyActivitySelection) {
        guard let currentEnd = sessionEnd,
              let newEnd = Calendar.current.date(byAdding: .minute, value: minutes, to: currentEnd)
        else { return }

        backend.cancelExpiry()

        do {
            try backend.scheduleExpiry(from: Date(), to: newEnd)
            sessionEnd = newEnd
            lastError = nil
        } catch {
            // Old schedule is already gone, so the shield has no owner. Drop it.
            backend.clear()
            sessionEnd = nil
            lastError = "Extend failed — shield removed to stay safe: \(error)"
        }
    }

    func end() {
        backend.cancelExpiry()
        backend.clear()
        sessionEnd = nil
        lastError = nil
    }
}
