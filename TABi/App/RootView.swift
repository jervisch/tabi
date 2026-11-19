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
                // Thin cream ring around the vermilion disc
                Circle()
                    .stroke(TABiColor.washi, lineWidth: 3)
                    .frame(width: 64, height: 64)

                Circle()
                    .fill(TABiColor.vermilion)
                    .frame(width: 56, height: 56)
            }
        }
        .buttonStyle(PressableStyle(isPressed: $isPressed))
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

/// Hand-drawn vermilion underline beneath the selected nav label.
private struct HandDrawnUnderline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        path.move(to: CGPoint(x: rect.minX, y: midY + 1.5))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: midY - 1),
            control: CGPoint(x: rect.midX, y: midY + 3)
        )
        return path
    }
}

struct RootView: View {
    @State private var screen: Screen = .atlas
    @State private var isCameraPresented = false
    @State private var isCameraPressed = false

    var body: some View {
        ZStack {
            // ── Screens ──────────────────────────────────────────────
            Group {
                switch screen {
                case .atlas:
                    AtlasView()
                case .memories:
                    MemoriesView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // ── Bottom navigation (persistent, warm-washi strip) ─────
            VStack {
                Spacer()
                bottomNav
            }
        }
        .background(TABiColor.washi.ignoresSafeArea())
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraView()
        }
        .animation(.easeOut(duration: 0.25), value: screen)
    }

    // MARK: - Bottom nav

    private var bottomNav: some View {
        ZStack(alignment: .top) {
            // Washi strip — extends into the bottom safe area
            TABiColor.washi
                .frame(height: 76)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.06), radius: 6, y: -2)

            // Map · Memories — English labels only, no icons
            HStack(alignment: .top) {
                navLabel("Map", isSelected: screen == .atlas) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        screen = .atlas
                    }
                }

                Spacer()

                navLabel("Memories", isSelected: screen == .memories) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        screen = .memories
                    }
                }
            }
            .padding(.horizontal, 44)
            .padding(.top, 16)

            // Center shutter — slightly overlaps the strip's top edge
            ShutterButton(isPressed: $isCameraPressed) {
                isCameraPresented = true
            }
            .offset(y: -14)
        }
    }

    private func navLabel(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(title)
                    .font(TABiFont.placeEnglish(19, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(TABiColor.sumi.opacity(isSelected ? 1 : 0.55))

                HandDrawnUnderline()
                    .stroke(
                        TABiColor.vermilion,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 38, height: 5)
                    .opacity(isSelected ? 1 : 0)
            }
            .fixedSize()
        }
        .buttonStyle(.plain)
    }
}
