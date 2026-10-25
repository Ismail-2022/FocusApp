import FamilyControls
import SwiftUI

/// SPIKE TASK 1: does `.individual` authorization actually grant on this device
/// and this Apple ID? This is the first thing that can kill Path B.
@MainActor
final class AuthorizationManager: ObservableObject {
    @Published var status: AuthorizationStatus = .notDetermined
    @Published var lastError: String?

    init() {
        status = AuthorizationCenter.shared.authorizationStatus
    }

    func requestAuthorization() async {
        do {
            // `.individual` = this user, no parent/guardian Apple ID required.
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            status = AuthorizationCenter.shared.authorizationStatus
            lastError = nil
        } catch {
            // Log the FULL error verbatim into the spike findings log.
            // Entitlement problems surface here, and the message matters.
            lastError = String(describing: error)
            status = AuthorizationCenter.shared.authorizationStatus
        }
    }
}
