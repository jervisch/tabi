import SwiftUI
import SwiftData

@main
struct TABiApp: App {
    @State private var isSplashVisible = true
    @State private var environment: AppEnvironment

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainerFactory.make()
        } catch {
            fatalError("Failed to open TABi store: \(error)")
        }
        _environment = State(initialValue: AppEnvironment(container: container))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isSplashVisible {
                    SplashView()
                } else {
                    RootView()
                        .environment(environment)
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
