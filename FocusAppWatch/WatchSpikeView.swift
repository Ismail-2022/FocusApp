import SwiftUI

/// THROWAWAY watch UI. Proves the watch can drive the phone. Nothing more.
struct WatchSpikeView: View {
    @StateObject private var connector = WatchConnector()

    var body: some View {
        VStack(spacing: 8) {
            if let end = connector.sessionEnd, end > Date() {
                Text(end, style: .timer)
                    .font(.title2.monospacedDigit())
                Button("+\(FocusSessionConstants.extendMinutes) min") { connector.extend() }
                Button("End", role: .destructive) { connector.end() }
            } else {
                Button("Start \(FocusSessionConstants.defaultSessionMinutes) min") { connector.start(minutes: FocusSessionConstants.defaultSessionMinutes) }
                Button("Start \(FocusSessionConstants.minimumSessionMinutes) min") { connector.start(minutes: FocusSessionConstants.minimumSessionMinutes) }
            }

            Text(connector.statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
