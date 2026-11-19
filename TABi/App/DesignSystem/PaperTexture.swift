import SwiftUI

/// Subtle paper grain over washi backgrounds (illustrated-journal texture).
struct PaperGrainOverlay: View {
    var opacity: Double = 0.04

    var body: some View {
        Canvas { context, size in
            var rng = SystemRandomNumberGenerator()
            let count = Int(size.width * size.height / 40)
            for _ in 0..<count {
                let x = CGFloat.random(in: 0..<size.width, using: &rng)
                let y = CGFloat.random(in: 0..<size.height, using: &rng)
                let a = CGFloat.random(in: 0.15...0.55, using: &rng)
                let rect = CGRect(x: x, y: y, width: 1, height: 1)
                context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(a)))
            }
        }
        .opacity(opacity)
        .allowsHitTesting(false)
    }
}

extension View {
    func washiBackground() -> some View {
        background {
            ZStack {
                TABiColor.washi.ignoresSafeArea()
                PaperGrainOverlay()
            }
        }
    }
}
