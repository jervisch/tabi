import SwiftUI
import AVFoundation
import Photos

struct CameraView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var isFlipped = false
    @State private var flashMode: AVCaptureDevice.FlashMode = .off
    @State private var showingSavedCard = false
    @State private var capturedImage: UIImage?
    @State private var capturedComponents: PlaceComponents?
    @State private var savedDate: Date?
    @State private var cameraDenied = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 3:4 viewfinder — centered in black background
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height * 0.75)
                let insetX = (geo.size.width - size) / 2
                let insetY = (geo.size.height - size * (4.0/3.0)) / 2

                VideoPreviewLayer(session: env.camera.session)
                    .frame(width: size, height: size * (4.0/3.0))
                    .position(x: insetX + size / 2, y: insetY + size * (4.0/3.0) / 2)
            }

            // Controls — × alone at top-left; flash / shutter / flip at bottom
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(20)

                Spacer()

                HStack {
                    // Flash toggle — icon only, vermilion when active
                    Button {
                        switch flashMode {
                        case .off: flashMode = .on
                        case .on: flashMode = .auto
                        case .auto: flashMode = .off
                        @unknown default: flashMode = .off
                        }
                    } label: {
                        Image(systemName: flashMode == .off ? "flashoff" : flashMode == .on ? "flash.fill" : "flash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(flashMode == .off ? .white.opacity(0.7) : TABiColor.vermilion)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Flash")

                    Spacer()

                    // Shutter button — circular vermilion, bottom center
                    Button {
                        Task { await takePhoto() }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(TABiColor.vermilion)
                                .frame(width: 66, height: 66)
                                .shadow(color: TABiColor.vermilion.opacity(0.5), radius: 10, y: 2)
                            Circle()
                                .stroke(TABiColor.washi, lineWidth: 3)
                                .frame(width: 74, height: 74)
                            if env.isCapturing {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                    }
                    .disabled(env.isCapturing)
                    .accessibilityLabel("Shutter")

                    Spacer()

                    // Flip camera
                    Button {
                        try? env.camera.flipCamera()
                        isFlipped.toggle()
                    } label: {
                        Image(systemName: "camera.rotate")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Flip camera")
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 40)
            }

            // Permission denied — quiet caption, no modal
            if cameraDenied {
                VStack(spacing: 6) {
                    Text("Camera access is off")
                        .font(TABiFont.placeEnglish(15, weight: .medium))
                        .foregroundColor(.white)
                    Text("Enable it in Settings to take photos.")
                        .font(TABiFont.caption(11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            // Polaroid confirmation — the memory is already saved above.
            // Tap or1.5 s timeout hides only the card; the camera stays open.
            if showingSavedCard, let image = capturedImage {
                MemorySavedCardView(
                    image: image,
                    components: capturedComponents,
                    capturedAt: savedDate ?? Date(),
                    onDismiss: { hideSavedCard() }
                )
                .task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    guard !Task.isCancelled else { return }
                    hideSavedCard()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .task {
            // Camera opens immediately: ask permission, then run the session.
            let granted = await env.camera.requestPermission()
            cameraDenied = !granted
            if granted {
                try? env.camera.start()
            }
        }
        .onDisappear {
            env.camera.stop()
        }
    }

    /// Hides only the polaroid — the camera screen stays open.
    private func hideSavedCard() {
        withAnimation(.easeOut(duration: 0.25)) {
            showingSavedCard = false
        }
    }

    private func takePhoto() async {
        env.isCapturing = true
        env.camera.flashMode = flashMode
        do {
            let (processedImage, components) = try await env.takePhoto()
            // `takePhoto` clears `isCapturing` on exit — re-assert while saving.
            env.isCapturing = true
            let capturedAt = Date()
            try await env.saveMemory(
                processed: processedImage,
                components: components,
                capturedAt: capturedAt
            )
            capturedImage = processedImage
            capturedComponents = components
            savedDate = capturedAt
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showingSavedCard = true
            }
        } catch {
            // Degrade gracefully — keep camera open, no crash
        }
        env.isCapturing = false
    }
}

// MARK: - Memory Saved Polaroid

/// Post-capture confirmation: white polaroid frame with the photo, a bottom
/// strip carrying "Memory saved", the place, and the date. Tap hides the card
/// (the camera stays open); it also clears itself after 1.5 seconds.
struct MemorySavedCardView: View {
    let image: UIImage
    let components: PlaceComponents?
    let capturedAt: Date
    let onDismiss: () -> Void

    private var placeLine: String? {
        guard let components else { return nil }
        let parts = [components.city, components.prefecture]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        // City and prefecture are often the same name — collapse duplicates.
        let unique = parts.reduce(into: [String]()) { acc, part in
            if !acc.contains(where: { $0.caseInsensitiveCompare(part) == .orderedSame }) {
                acc.append(part)
            }
        }
        return unique.isEmpty ? nil : unique.joined(separator: " · ")
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 260, height: 300)
                    .clipped()
                    .padding(.top, 14)
                    .padding(.horizontal, 14)

                VStack(spacing: 4) {
                    Text("Memory saved")
                        .font(TABiFont.placeEnglish(15, weight: .medium))
                        .foregroundStyle(TABiColor.sumi)
                    Text("Added to your Atlas")
                        .font(TABiFont.caption(11))
                        .foregroundStyle(TABiColor.sumi.opacity(0.5))

                    if let placeLine {
                        Text(placeLine)
                            .font(TABiFont.placeEnglish(13))
                            .foregroundStyle(TABiColor.sumi.opacity(0.75))
                            .padding(.top, 6)
                    }

                    Text(capturedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(TABiFont.caption(11))
                        .foregroundStyle(TABiColor.sumi.opacity(0.45))
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 18, y: 8)
            .padding(.horizontal, 48)
            .contentShape(Rectangle())
            .onTapGesture(perform: onDismiss)
        }
    }
}

// MARK: - Video Preview Layer

struct VideoPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewSurface {
        let view = PreviewSurface()
        view.preview.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewSurface, context: Context) {}

    /// Keeps the preview layer sized to the view — `bounds` is `.zero`
    /// at `makeUIView` time, so the frame must track layout.
    final class PreviewSurface: UIView {
        let preview = AVCaptureVideoPreviewLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            preview.videoGravity = .resizeAspectFill
            layer.insertSublayer(preview, at: 0)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }

        override func layoutSubviews() {
            super.layoutSubviews()
            preview.frame = bounds
        }
    }
}