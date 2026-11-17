import SwiftUI

struct TravelPrintView: View {
    let image: UIImage
    let components: PlaceComponents
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            // Warm paper background
            Color(red: 0.96, green: 0.92, blue: 0.86)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Photo centered
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 400)
                    .padding(40)

                // Location + date
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text(components.prefecture ?? "")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)

                        Text("/ ")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Text(components.city ?? "")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                    }

                    HStack(spacing: 6) {
                        Text(components.country ?? "")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Text("• ")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)

                        if let date = components.placeName != nil ? nil : Date() {
                            // Use capture timestamp - but we don't have it here;
                            // will be filled by the caller
                            Text("2026")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 40)

                // Save button
                Button("Save to Atlas") {
                    onSave()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 16)
                .background(TABiColor.vermilion)
                .clipShape(Capsule())
                .shadow(color: TABiColor.vermilion.opacity(0.3), radius: 8, y: 4)

                // Cancel button
                Button("Cancel") {
                    onCancel()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 12)
                .background(TABiColor.sumi)
                .clipShape(Capsule())
                .shadow(color: TABiColor.sumi.opacity(0.3), radius: 8, y: 4)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}