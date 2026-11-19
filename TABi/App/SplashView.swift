import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            TABiColor.washi.ignoresSafeArea()
            VStack(spacing: 14) {
                Text("旅")
                    .font(TABiFont.title(84))
                    .foregroundStyle(TABiColor.sumi)
                Text("TABi")
                    .font(TABiFont.placeEnglish(16, weight: .medium))
                    .tracking(10)
                    .foregroundStyle(TABiColor.sumi.opacity(0.65))
            }
        }
    }
}

#Preview {
    SplashView()
}
