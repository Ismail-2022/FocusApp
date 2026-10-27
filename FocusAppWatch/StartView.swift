import SwiftUI

struct StartView: View {
    @EnvironmentObject private var session: FocusSession

    var body: some View {
        VStack(spacing: 6) {
            Text("\(session.selectedMinutes)")
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())

            Text("minutes")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Picker("Duration", selection: $session.selectedMinutes) {
                ForEach(FocusSessionConstants.durations, id: \.self) { minutes in
                    Text("\(minutes)").tag(minutes)
                }
            }
            .pickerStyle(.navigationLink)
            .labelsHidden()
            .frame(height: 34)

            Button {
                withAnimation { session.start() }
            } label: {
                Text("Start")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding(.horizontal, 4)
    }
}
