import SwiftUI

/// THROWAWAY watch UI. Proves the watch can drive the phone. Nothing more.
struct WatchSpikeView: View {
    @StateObject private var connector = WatchConnector()

    var body: some View {
        VStack(spacing: 8) {
            if let end = connector.sessionEnd, end > Date() {
                Text(end, style: .timer)
                    .font(.title2.monospacedDigit())
                Button("+10 min") { connector.extend() }
                Button("End", role: .destructive) { connector.end() }
            } else {
                Button("Start 25 min") { connector.start(minutes: 25) }
                Button("Start 15 min") { connector.start(minutes: 15) }
            }

            Text(connector.statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
