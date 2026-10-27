import SwiftUI

/// Night, before the session. The Crown picks the length — it's the one input
/// unique to this device, and a system picker wastes it.
struct StartView: View {
    @EnvironmentObject private var session: FocusSession

    @State private var crown: Double = 0
    @FocusState private var crownFocused: Bool

    private var durations: [Int] { FocusSessionConstants.durations }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            Text("\(session.selectedMinutes)")
                .font(TypeScale.numerals(62, weight: .light))
                .foregroundStyle(Palette.ink)
                .contentTransition(.numericText())

            Text(session.selectedMinutes == 1 ? "minute" : "minutes")
                .font(TypeScale.label)
                .foregroundStyle(Palette.inkMuted)
                .padding(.top, -2)

            Spacer(minLength: 0)

            if !session.alertsEnabled {
                Text("Alerts are off. Turn on notifications to be told when a session ends.")
                    .font(TypeScale.note)
                    .foregroundStyle(Palette.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 6)
            }

            Button("Begin") {
                session.start()
            }
            .buttonStyle(ChipButtonStyle(fill: Palette.field(at: 0.12)))
        }
        .padding(.horizontal, 6)
        .focusable(true)
        .focused($crownFocused)
        .digitalCrownRotation(
            $crown,
            from: 0,
            through: Double(durations.count - 1),
            by: 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crown) { _, value in
            let index = min(max(Int(value.rounded()), 0), durations.count - 1)
            guard durations[index] != session.selectedMinutes else { return }
            withAnimation(.snappy(duration: 0.2)) {
                session.selectedMinutes = durations[index]
            }
        }
        .onAppear {
            crown = Double(durations.firstIndex(of: session.selectedMinutes) ?? 1)
            crownFocused = true
        }
    }
}
