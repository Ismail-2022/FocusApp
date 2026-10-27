import SwiftUI

/// The session itself. The dawn behind the numerals is the real readout; these
/// digits are the precision layer on top of it.
struct ActiveSessionView: View {
    @EnvironmentObject private var session: FocusSession

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            // The horizon climbs through this type as the session runs, so the
            // readout carries its own soft pool of night rather than relying on
            // whatever happens to be behind it at the time.
            VStack(spacing: 0) {
                Text(countdown)
                    .font(TypeScale.numerals(52))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .accessibilityLabel("\(Int(session.remaining / 60)) minutes remaining")

                if let endsAt = session.endsAt {
                    Text("ends \(endsAt.formatted(date: .omitted, time: .shortened))")
                        .font(TypeScale.note)
                        .foregroundStyle(Palette.ink.opacity(0.7))
                }
            }
            // Tight shadow rather than a scrim behind the block: a soft dark
            // pool is invisible against the night but reads as a smudge once
            // the field brightens. This hugs the glyphs instead, so it works at
            // both ends of the session.
            .shadow(color: Palette.void.opacity(0.9), radius: 2)
            .shadow(color: Palette.void.opacity(0.5), radius: 6)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Button("+\(FocusSessionConstants.extendMinutes)") {
                    session.extend()
                }

                Button("End") {
                    session.cancel()
                }
            }
            .buttonStyle(ChipButtonStyle())
        }
        .padding(.horizontal, 6)
    }

    private var countdown: String {
        let total = Int(session.remaining.rounded(.up))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

/// Full dawn. Held for a few seconds so finishing registers as an arrival
/// rather than the screen quietly resetting itself.
struct CompletedView: View {
    @EnvironmentObject private var session: FocusSession

    var body: some View {
        VStack(spacing: 2) {
            Spacer(minLength: 0)

            Text("Done")
                .font(TypeScale.numerals(40, weight: .light))
                .foregroundStyle(Palette.ink)
                .shadow(color: Palette.void.opacity(0.5), radius: 4)

            Text("\(session.completedMinutes) minutes focused")
                .font(TypeScale.note)
                .foregroundStyle(Palette.ink.opacity(0.75))

            Spacer(minLength: 0)

            Button("New session") {
                session.acknowledge()
            }
            .buttonStyle(ChipButtonStyle())
        }
        .padding(.horizontal, 6)
    }
}
