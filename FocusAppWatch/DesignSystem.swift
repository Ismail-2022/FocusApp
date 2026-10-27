import SwiftUI

/// A session is a night that ends in dawn.
///
/// The field rising behind the countdown is the primary readout — the numerals
/// are the precision layer on top of it. Colour travels from deep petrol through
/// violet to rose as the session completes, so "nearly finished" is legible at a
/// glance without reading a single digit. There is deliberately no separate
/// alarm colour for the final minutes: by then the dawn has already arrived.
enum Palette {

    /// Night. Near-black with a blue cast — dark enough to switch OLED pixels
    /// off, but not the flat UI black that reads as "no decision was made here".
    static let void = Color(red: 0.016, green: 0.024, blue: 0.047)   // #04060C

    static let ink = Color(red: 0.929, green: 0.945, blue: 0.957)    // #EDF1F4
    static let inkMuted = Color(red: 0.561, green: 0.627, blue: 0.678) // #8FA0AD

    /// Controls sit on a field that changes colour beneath them over the course
    /// of a session, so they lighten whatever is behind and carry a defined
    /// edge. A dark fill disappears against the night; a light one washes out
    /// against the dawn. The stroke is what makes them a control at both ends.
    static let chipFill = ink.opacity(0.14)
    static let chipStroke = ink.opacity(0.3)

    /// Field stops, travelled in order as the session elapses.
    private static let stops: [(r: Double, g: Double, b: Double)] = [
        (0.055, 0.208, 0.314),  // #0E3550 petrol — the small hours
        (0.275, 0.208, 0.435),  // #46356F violet — first light
        (0.690, 0.290, 0.388)   // #B04A63 rose   — dawn
    ]

    /// The field colour at a given elapsed fraction (0...1).
    static func field(at progress: Double) -> Color {
        let (r, g, b) = components(at: progress)
        return Color(red: r, green: g, blue: b)
    }

    /// The horizon itself: the field colour lifted toward white. This is the one
    /// bright element in the design, so everything else stays quiet.
    static func horizon(at progress: Double) -> Color {
        let (r, g, b) = components(at: progress)
        let lift = 0.55
        return Color(
            red: r + (1 - r) * lift,
            green: g + (1 - g) * lift,
            blue: b + (1 - b) * lift
        )
    }

    private static func components(at progress: Double) -> (Double, Double, Double) {
        let clamped = min(max(progress, 0), 1)
        // Eased so the night holds. A linear walk through the stops reaches
        // violet barely a third of the way in, which tells the user nothing —
        // colour should only start meaning "nearly done" when it nearly is.
        let eased = pow(clamped, 1.8)
        let scaled = eased * Double(stops.count - 1)
        let index = min(Int(scaled), stops.count - 2)
        let t = scaled - Double(index)
        let a = stops[index]
        let b = stops[index + 1]
        return (
            a.r + (b.r - a.r) * t,
            a.g + (b.g - a.g) * t,
            a.b + (b.b - a.b) * t
        )
    }
}

enum TypeScale {
    /// Monospaced so digits hold their width as they change — a proportional
    /// face makes a countdown twitch once per second.
    static func numerals(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static let label = Font.system(size: 12, weight: .medium)
    static let note = Font.system(size: 11, weight: .regular)
}


/// The only button treatment in the app.
struct ChipButtonStyle: ButtonStyle {
    var fill: Color = Palette.chipFill

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypeScale.label)
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(Capsule().fill(fill))
            .overlay(Capsule().strokeBorder(Palette.chipStroke, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.55 : 1)
    }
}
