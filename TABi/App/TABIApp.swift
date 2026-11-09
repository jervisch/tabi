import SwiftUI

@main
struct TABiApp: App {
    @State private var isSplashVisible = true

    var body: some Scene {
        WindowGroup {
            Group {
                if isSplashVisible {
                    SplashView()
                } else {
                    RootView()
                }
            }
            .task {
                try? await Task.sleep(for: .milliseconds(900))
                withAnimation(.easeInOut(duration: 0.4)) {
                    isSplashVisible = false
                }
            }
        }
    }
}
