import SwiftUI
import AVFoundation

struct CameraView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var permissionDenied = false
    @State private var capturing = false
    @State private var errorMessage: String?
    @State private var previewImage: UIImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                placeLabel

                Spacer()

                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 40)
                        .padding(.bottom, 12)
                }

                shutterArea
                    .padding(.bottom, 28)
            }

            if env.showMemorySavedCard {
                MemorySavedCardView(
                    image: env.lastSavedImage,
                    components: env.currentComponents,
                    onDone: {
                        env.dismissSavedCard()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }

            if permissionDenied {
                permissionOverlay
            }
        }
        .task {
            let ok = await env.camera.requestPermission()
            if ok {
                try? env.camera.start()
            } else {
                permissionDenied = true
            }
        }
        .onDisappear {
            env.camera.stop()
            env.dismissSavedCard()
        }
        .animation(.spring(duration: 0.35), value: env.showMemorySavedCard)
    }

    private var placeLabel: some View {
        VStack(spacing: 4) {
            if let components = env.currentComponents {
                Text(labelEnglish(components))
                    .font(TABiFont.placeEnglish(17))
                    .foregroundStyle(.white)
                    .tracking(2)
                Text(labelJapanese(components))
                    .font(TABiFont.placeJapanese(15))
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                Text("LOCATING…")
                    .font(TABiFont.placeEnglish(15))
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(3)
                Text("現在地を確認中")
                    .font(TABiFont.placeJapanese(13))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .shadow(color: .black.opacity(0.4), radius: 6, y: 1)
    }

    private func labelEnglish(_ c: PlaceComponents) -> String {
        if let city = c.city, let place = c.placeName {
            return "\(city.uppercased()) / \(place.uppercased())"
        }
        if let city = c.city { return city.uppercased() }
        if let prefecture = c.prefecture { return prefecture.uppercased() }
        return "SOMEWHERE"
    }

    private func labelJapanese(_ c: PlaceComponents) -> String {
        var parts: [String] = []
        if let prefecture = c.prefecture { parts.append(prefecture) }
        if let place = c.placeName { parts.append(place) }
        if parts.isEmpty { return "どこか" }
        return parts.joined(separator: " · ")
    }

    private var shutterArea: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Button {
                Task { await takePhoto() }
            } label: {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 3)
                        .frame(width: 72, height: 72)
                    Circle()
                        .fill(.white)
                        .frame(width: 60, height: 60)
                    if capturing {
                        ProgressView()
                            .tint(.black)
                    }
                }
            }
            .disabled(capturing)
            .accessibilityLabel("Shutter")

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, TABiSpacing.lg)
    }

    private func takePhoto() async {
        capturing = true
        errorMessage = nil
        defer { capturing = false }
        await env.captureAndRemember()
        previewImage = env.lastSavedImage
        if env.lastSavedMemory == nil {
            errorMessage = "Could not save memory."
        }
    }

    private var permissionOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.white.opacity(0.8))
            Text("Camera access is needed to take memories.")
                .font(TABiFont.body())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Close") { dismiss() }
                .buttonStyle(.bordered)
                .tint(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.85).ignoresSafeArea())
    }
}

struct MemorySavedCardView: View {
    let image: UIImage?
    let components: PlaceComponents?
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.white
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                } else {
                    Rectangle()
                        .fill(TABiColor.sumi.opacity(0.08))
                        .frame(height: 220)
                        .padding(10)
                }
            }
            .frame(width: 260, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .shadow(color: .black.opacity(0.35), radius: 16, y: 8)

            VStack(spacing: 6) {
                Text("✦ MEMORY SAVED ✦")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(TABiColor.sumi.opacity(0.7))
                if let components {
                    Text(components.city ?? components.prefecture ?? "")
                        .font(TABiFont.title(22))
                        .foregroundStyle(TABiColor.sumi)
                    if let ja = components.prefecture {
                        Text(ja)
                            .font(TABiFont.placeJapanese(14))
                            .foregroundStyle(TABiColor.sumi.opacity(0.55))
                    }
                }
                Text("Added to your Atlas")
                    .font(TABiFont.caption())
                    .foregroundStyle(TABiColor.moss)
                    .padding(.top, 4)
            }
            .padding(.top, 18)
            .frame(width: 280)
            .padding(.bottom, 24)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .shadow(color: .black.opacity(0.3), radius: 18, y: 10)

            Button {
                onDone()
            } label: {
                Text("Continue")
                    .font(TABiFont.body())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(TABiColor.sumi, in: Capsule())
            }
            .padding(.top, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.55).ignoresSafeArea())
    }
}
