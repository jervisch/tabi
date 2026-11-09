import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            TABiColor.washi.ignoresSafeArea()
            VStack(spacing: 12) {
                Text("旅")
                    .font(.system(size: 72, weight: .light, design: .serif))
                    .foregroundStyle(TABiColor.sumi)
                Text("TABI")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .tracking(8)
                    .foregroundStyle(TABiColor.sumi.opacity(0.7))
            }
        }
    }
}

#Preview {
    SplashView()
}
