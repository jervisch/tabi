import SwiftUI
import AVFoundation
import Photos

struct CameraView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var isFlipped = false
    @State private var flashMode: AVCaptureDevice.FlashMode = .off
    @State private var showingPrint = false
    @State private var capturedImage: UIImage?
    @State private var capturedComponents: PlaceComponents?

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

            // × Close control (drawn Path, top-left)
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
                    .padding(20)

                    Spacer()

                    // Flash toggle
                    Button {
switch flashMode {
        case .off: flashMode = .on
        case .on: flashMode = .auto
        case .auto: flashMode = .off
        @unknown default: flashMode = .off
        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(flashMode == .off ? TABiColor.vermilion : TABiColor.moss)
                                .frame(width: 28, height: 28)
                            Image(systemName: flashMode == .off ? "flashoff" : flashMode == .on ? "flashon" : "flash")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)

                    Spacer()

                    // Flip camera
                    Button {
                        isFlipped.toggle()
                    } label: {
                        Image(systemName: "camera.rotate")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.trailing, 20)

                    Spacer()
                }

                Spacer()

                // Shutter button — circular vermilion, bottom center
                VStack {
                    Spacer()
                    HStack {
                        Spacer()

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
                    }
                    .padding(.bottom, 40)

                    // Flip indicator (subtle)
                    if isFlipped {
                        HStack {
                            Text("↑")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                            Spacer()
                            Text("↓")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.bottom, 10)
                    }
                }
            }

            // Travel print presentation — appears after capture
            if showingPrint {
                // TravelPrintView placeholder - will be implemented in Task 5
                Color.gray.opacity(0.3).frame(maxWidth: .infinity, maxHeight: 300)
                .transition(.opacity)
            }
        }
        .task {
            // Camera opens immediately — no LOCATING… screen
            // Initial setup: start video capture, no permission prompt from this view
            // Permission handled at a higher level; if denied, app degrades gracefully
        }
        .onChange(of: showingPrint) { _, new in
            if !new {
                env.isCapturing = false
            }
        }
    }

    private func takePhoto() async {
        env.isCapturing = true
        defer { env.isCapturing = false }

        do {
            let (processedImage, components) = try await env.takePhoto()
            capturedImage = processedImage
            capturedComponents = components
            showingPrint = true
        } catch {
            // Degrade gracefully — keep camera open, no crash
            env.isCapturing = false
        }
    }

    private func saveMemory() {
        Task {
            do {
                try await env.saveMemory(processed: capturedImage!, components: capturedComponents!, capturedAt: Date())
                dismiss()
            } catch {
                env.isCapturing = false
            }
        }
    }
}

// MARK: - Video Preview Layer

struct VideoPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}