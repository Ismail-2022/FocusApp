import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject private var session: FocusSession

    var body: some View {
        VStack(spacing: 8) {
            Text(countdown)
                .font(.system(size: 40, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.orange)

            if let endsAt = session.endsAt {
                Text("until \(endsAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Button("+\(FocusSessionConstants.extendMinutes)") {
                    session.extend()
                }
                .tint(.orange)

                Button(role: .destructive) {
                    withAnimation { session.cancel() }
                } label: {
                    Image(systemName: "xmark")
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 4)
    }

    private var countdown: String {
        let total = Int(session.remaining.rounded(.up))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
