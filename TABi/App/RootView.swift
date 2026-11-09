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
            .offset(y: -8)

            tabButton(.memories)
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            TABiColor.washi
                .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
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
