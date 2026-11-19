import SwiftUI
import Photos

struct PhotoDetailView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    let memory: Memory
    @State private var exportMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TABiSpacing.md) {
                    if let image = UIImage(data: memory.imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .padding(.horizontal, TABiSpacing.md)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(memory.placeName ?? memory.city ?? "Memory")
                            .font(TABiFont.title(24))
                            .foregroundStyle(TABiColor.sumi)
                        if let city = memory.city {
                            Text(city)
                                .font(TABiFont.placeJapanese(15))
                                .foregroundStyle(TABiColor.sumi.opacity(0.55))
                        }
                        Text(memory.capturedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(TABiFont.monoDate())
                            .foregroundStyle(TABiColor.sumi.opacity(0.55))
                        if let prefecture = memory.prefecture {
                            Text(prefecture)
                                .font(TABiFont.caption())
                                .foregroundStyle(TABiColor.moss)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, TABiSpacing.md)

                    if let exportMessage {
                        Text(exportMessage)
                            .font(TABiFont.caption())
                            .foregroundStyle(TABiColor.indigo)
                            .padding(.horizontal, TABiSpacing.md)
                    }

                    Button {
                        Task {
                            do {
                                guard await env.exporter.requestAddPermission() else {
                                    exportMessage = "Photo library permission denied."
                                    return
                                }
                                try await env.exporter.export(jpegData: memory.imageData)
                                exportMessage = "Saved to Photos."
                            } catch {
                                exportMessage = "Could not save to Photos."
                            }
                        }
                    } label: {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                            .font(TABiFont.body())
                            .foregroundStyle(TABiColor.sumi)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(TABiColor.sumi.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal, TABiSpacing.md)
                    .padding(.bottom, TABiSpacing.xl)
                }
                .padding(.top, TABiSpacing.sm)
            }
            .background(TABiColor.washi.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TABiColor.sumi)
                }
            }
        }
    }
}
