import SwiftUI

enum Screen: String, CaseIterable, Identifiable {
    case atlas
    case memories

    var id: String { rawValue }
}

struct ShutterButton: View {
    @Binding var isPressed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(TABiColor.vermilion)
                    .frame(width: 48, height: 48)
                    .scaleEffect(isPressed ? 0.94 : 1.0)
                    .opacity(isPressed ? 0.85 : 1)

                Image(systemName: "camera")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PressableStyle(isPressed: $isPressed))
        .highPriorityGesture(
            DragGesture()
                .onEnded { value in
                    let horizontalSwipe = abs(value.translation.width) > abs(value.translation.height) + 20
                    if horizontalSwipe && value.translation.width > 0 {
                        // right-to-left swipe on Atlas → Memories
                        // left-to-right swipe on Memories → Atlas handled elsewhere
                    }
                }
        )
    }
}

struct PressableStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct RootView: View {
    @State private var screen: Screen = .atlas
    @State private var isCameraPresented = false
    @State private var isCameraPressed = false

    var body: some View {
        ZStack {
            Group {
                switch screen {
                case .atlas:
                    AtlasView()
                        .highPriorityGesture(
                            DragGesture()
                                .onEnded { value in
                                    // Right-edge swipe leftward → Memories
                                    if value.translation.width < -40 && abs(value.translation.width) > abs(value.translation.height) {
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            screen = .memories
                                        }
                                    }
                                }
                        )
                        .highPriorityGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    // pinch-to-zoom handled in IllustratedJapanMapView
                                }
                        )
                case .memories:
                    MemoriesView()
                        .highPriorityGesture(
                            DragGesture()
                                .onEnded { value in
                                    // Left-edge swipe rightward → Atlas
                                    if value.translation.width > 40 && abs(value.translation.width) > abs(value.translation.height) {
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            screen = .atlas
                                        }
                                    }
                                }
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Camera button: circular vermilion, bottom safe area, no label
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ShutterButton(isPressed: $isCameraPressed) {
                        isCameraPresented = true
                    }
                    .padding(.bottom, 40)
                }
            }

            // Edge-swipe indicator (subtle) — optional, for discoverability
            // Atlas→Memories: right edge drag area
            if screen == .atlas {
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(TABiColor.sumi.opacity(0.08))
                        .frame(width: 44)
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    if value.translation.width < -40 && abs(value.translation.width) > abs(value.translation.height) {
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            screen = .memories
                                        }
                                    }
                                }
                        )
                }
            } else {
                // Memories→Atlas: left edge drag area
                HStack {
                    Rectangle()
                        .fill(TABiColor.sumi.opacity(0.08))
                        .frame(width: 44)
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    if value.translation.width > 40 && abs(value.translation.width) > abs(value.translation.height) {
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            screen = .atlas
                                        }
                                    }
                                }
                        )
                    Spacer()
                }
            }
        }
        .background(TABiColor.washi.ignoresSafeArea())
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraView()
        }
        .animation(.easeOut(duration: 0.25), value: screen)
    }
}
