import SwiftUI

struct MemoryGridView: View {
    let memories: [Memory]
    @State private var selected: Memory?

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        Group {
            if memories.isEmpty {
                Text("No memories yet")
                    .font(TABiFont.body())
                    .foregroundStyle(TABiColor.sumi.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(memories) { memory in
                        Button {
                            selected = memory
                        } label: {
                            MemoryThumb(memory: memory)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, TABiSpacing.md)
                .padding(.bottom, TABiSpacing.xl)
            }
        }
        .sheet(item: $selected) { memory in
            PhotoDetailView(memory: memory)
        }
    }
}

struct MemoryThumb: View {
    let memory: Memory

    var body: some View {
        ZStack {
            if let ui = uiImage {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(TABiColor.sumi.opacity(0.08))
                Image(systemName: "photo")
                    .foregroundStyle(TABiColor.sumi.opacity(0.25))
            }
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            if let place = memory.placeName {
                Text(place)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.35), in: Capsule())
                    .padding(6)
            }
        }
    }

    private var uiImage: UIImage? {
        UIImage(data: memory.imageData)
    }
}
