import FamilyControls
import SwiftUI

/// THROWAWAY SPIKE UI. Ugly on purpose — one button per acceptance criterion.
/// Do not design here. Task 1 builds the real UI, after the spike passes.
struct SpikeView: View {
    @StateObject private var auth = AuthorizationManager()
    // Injected by FocusAppApp so the watch bridge and the UI share one session.
    @EnvironmentObject private var selectionStore: AppSelectionStore
    @EnvironmentObject private var session: SessionController

    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            Form {
                if session.isDemo {
                    Section {
                        Label("DEMO MODE — nothing is actually blocked",
                              systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }

                Section("1 — Authorization") {
                    if session.isDemo {
                        Text("Skipped in demo mode")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Status: \(String(describing: auth.status))")
                        Button("Request .individual authorization") {
                            Task { await auth.requestAuthorization() }
                        }
                        if let error = auth.lastError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .textSelection(.enabled) // paste into the findings log
                        }
                    }
                }

                Section("2 — App selection") {
                    Text("Selected: \(selectionStore.selectedCount)")
                    if session.isDemo {
                        Button("Add 3 pretend apps") { selectionStore.addDemoSelection() }
                    } else {
                        Button("Pick apps to block") { showingPicker = true }
                    }
                }

                Section("3 — Session") {
                    Button("Start \(FocusSessionConstants.minimumSessionMinutes) min") {
                        session.start(minutes: FocusSessionConstants.minimumSessionMinutes,
                                      selection: selectionStore.selection)
                    }
                    Button("Extend +\(FocusSessionConstants.extendMinutes) min") {
                        session.extend(byMinutes: FocusSessionConstants.extendMinutes,
                                       selection: selectionStore.selection)
                    }
                    Button("End now", role: .destructive) { session.end() }
                }

                Section("4 — State") {
                    Text(session.sessionEnd.map { "Ends: \($0.formatted(date: .omitted, time: .standard))" }
                         ?? "No active session")
                    if let error = session.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .textSelection(.enabled)
                    }
                }

                if !session.isDemo {
                    Section("5 — Manual device tests") {
                        Text("• Open a blocked app → shielded?")
                        Text("• Force-quit mid-session → does the shield still lift?")
                        Text("• Reboot mid-session → does it still lift?")
                        Text("• Start from the watch with this app closed → works?")
                    }
                    .font(.caption)
                }
            }
            .navigationTitle(session.isDemo ? "Spike (Demo)" : "Path B Spike")
            .familyActivityPicker(isPresented: $showingPicker,
                                  selection: $selectionStore.selection)
        }
    }
}
