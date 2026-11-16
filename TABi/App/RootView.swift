import SwiftUI

enum RootTab: String, CaseIterable, Identifiable {
    case atlas
    case memories

    var id: String { rawValue }

    /// Japanese primary / English secondary (design kit nav).
    var titleJa: String {
        switch self {
        case .atlas: "地図"
        case .memories: "思い出"
        }
    }

    var titleEn: String {
        switch self {
        case .atlas: "Atlas"
        case .memories: "Memories"
        }
    }

    /// Asset-catalog illustration for the bottom bar.
    var iconAsset: String {
        switch self {
        case .atlas: "nav_atlas"
        case .memories: "nav_memories"
        }
    }
}

struct RootView: View {
    @State private var selection: RootTab = .atlas
    @State private var isCameraPresented = false
    @State private var isCameraPressed = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .atlas:
                    AtlasView()
                case .memories:
                    MemoriesView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
                .zIndex(1)
        }
        .background(TABiColor.washi.ignoresSafeArea())
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraView()
        }
    }

    /// Quiet, editorial — illustrations sitting on washi, labels set beneath.
    /// No containers, no selection backgrounds: state = opacity + slight scale.
    private var tabBar: some View {
        HStack(alignment: .top, spacing: 0) {
            tabButton(.atlas)

            Button {
                isCameraPresented = true
            } label: {
                Image("nav_camera")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 32)
                    // Centered on the illustration row; the focal point.
                    .offset(y: -4)
            }
            .accessibilityLabel("Camera")
            .buttonStyle(PressableStyle(isPressed: $isCameraPressed))
            .padding(.horizontal, 30)

            tabButton(.memories)
        }
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(TABiColor.washi.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(TABiColor.sumi.opacity(0.12))
                .frame(height: 0.5)
        }
    }

    private func tabButton(_ tab: RootTab) -> some View {
        let selected = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 6) {
                Image(tab.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .opacity(selected ? 1.0 : 0.55)
                    .scaleEffect(selected ? 1.0 : 0.96)
                    .animation(.easeOut(duration: 0.15), value: selected)

                // Labels live apart from the illustration.
                VStack(spacing: 1) {
                    Text(tab.titleJa)
                        .font(TABiFont.placeJapanese(10, weight: selected ? .medium : .regular))
                        .foregroundStyle(TABiColor.sumi.opacity(selected ? 0.85 : 0.5))

                    Text(tab.titleEn)
                        .font(TABiFont.placeEnglish(8))
                        .tracking(0.8)
                        .foregroundStyle(TABiColor.sumi.opacity(selected ? 0.55 : 0.35))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(tab.titleEn)
        .accessibilityAddTraits(selected ? .isSelected : [])
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
