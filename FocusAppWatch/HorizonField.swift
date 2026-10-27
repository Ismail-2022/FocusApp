import SwiftUI

/// The rising dawn. Height is elapsed time; colour is how near the end is.
///
/// This is the only thing in the app that moves on its own, and it moves at
/// exactly the rate time passes.
struct HorizonField: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Palette.horizon(at: progress))
                    .frame(height: 1.5)
                    .shadow(color: Palette.horizon(at: progress).opacity(0.35), radius: 3)

                LinearGradient(
                    colors: [
                        Palette.field(at: progress),
                        Palette.field(at: progress).opacity(0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(width: geo.size.width,
                   height: max(0, geo.size.height * min(max(progress, 0), 1)))
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
        .animation(.linear(duration: 1), value: progress)
        .accessibilityHidden(true)
    }
}
