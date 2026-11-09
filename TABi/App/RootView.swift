import SwiftUI

enum RootTab: String, CaseIterable, Identifiable {
    case atlas
    case memories

    var id: String { rawValue }

    var title: String {
        switch self {
        case .atlas: "Atlas"
        case .memories: "Memories"
        }
    }

    var systemImage: String {
        switch self {
        case .atlas: "map"
        case .memories: "photo.on.rectangle"
        }
    }
}

struct RootView: View {
    @State private var selection: RootTab = .atlas
    @State private var isCameraPresented = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .atlas:
                    AtlasPlaceholderView()
                case .memories:
                    MemoriesPlaceholderView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
        }
        .background(TABiColor.washi.ignoresSafeArea())
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.atlas)

            Button {
                isCameraPresented = true
            } label: {
                ZStack {
                    Circle()
                        .fill(TABiColor.sumi)
                        .frame(width: 56, height: 56)
                    Image(systemName: "camera")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(TABiColor.washi)
                }
            }
            .accessibilityLabel("Camera")
            .padding(.horizontal, 24)

            tabButton(.memories)
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            TABiColor.washi
                .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraPlaceholderView()
        }
    }

    private func tabButton(_ tab: RootTab) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 18, weight: .regular))
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selection == tab ? TABiColor.sumi : TABiColor.sumi.opacity(0.4))
            .frame(maxWidth: .infinity)
        }
        .accessibilityAddTraits(selection == tab ? .isSelected : [])
    }
}

struct AtlasPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Atlas")
                .font(.system(.largeTitle, design: .serif))
                .foregroundStyle(TABiColor.sumi)
            Text("0 / 47 prefectures · 0 cities")
                .font(.system(.subheadline, design: .default))
                .foregroundStyle(TABiColor.sumi.opacity(0.6))
            Image(systemName: "map")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(TABiColor.moss)
                .padding(.top, 24)
        }
    }
}

struct MemoriesPlaceholderView: View {
    var body: some View {
        Text("Memories")
            .font(.system(.largeTitle, design: .serif))
            .foregroundStyle(TABiColor.sumi)
    }
}

struct CameraPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Camera")
                    .font(.system(.title2, design: .serif))
                    .foregroundStyle(.white)
                Button("Close") { dismiss() }
                    .buttonStyle(.bordered)
                    .tint(.white)
            }
        }
    }
}

#Preview {
    RootView()
}
