import FamilyControls
import Foundation

/// Persists which apps the user chose to block.
///
/// NOTE: `ApplicationToken` is opaque — no bundle ID, no app name, by design.
/// We can count a selection and shield it. We can never list it in custom UI.
@MainActor
final class AppSelectionStore: ObservableObject {
    @Published var selection = FamilyActivitySelection() {
        didSet { save() }
    }

    /// Demo builds can't use FamilyActivityPicker (it needs real authorization),
    /// so the demo pretends a selection exists to let the flow run end to end.
    @Published var demoSelectedCount = 0

    private let key = "focusapp.selection"

    init() { load() }

    var selectedCount: Int {
        #if DEMO_MODE
        return demoSelectedCount
        #else
        return selection.applicationTokens.count + selection.categoryTokens.count
        #endif
    }

    var isEmpty: Bool { selectedCount == 0 }

    func addDemoSelection() {
        demoSelectedCount += 3
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return }
        selection = decoded
    }
}
