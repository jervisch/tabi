import Foundation
import AVFoundation
import UIKit

final class RealCamera: NSObject, CameraCapturing {
    let session = AVCaptureSession()
    var flashMode: AVCaptureDevice.FlashMode = .off
    private let photoOutput = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "tabi.camera")
    private var isConfigured = false
    private var currentInput: AVCaptureDeviceInput?
    private var currentPosition: AVCaptureDevice.Position = .back
    private var photoContinuation: CheckedContinuation<Data, Error>?

    var authorization: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestPermission() async -> Bool {
        switch authorization {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    func start() throws {
        guard authorization == .authorized else { throw CameraError.permissionDenied }
        try configureIfNeeded()
        queue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        queue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func flipCamera() throws {
        guard authorization == .authorized else { throw CameraError.permissionDenied }
        try configureIfNeeded()
        let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: newPosition
        ) else { return }
        let newInput = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(newInput) else { return }
        session.beginConfiguration()
        if let currentInput {
            session.removeInput(currentInput)
        }
        session.addInput(newInput)
        session.commitConfiguration()
        currentInput = newInput
        currentPosition = newPosition
    }

    func capturePhoto() async throws -> Data {
        guard authorization == .authorized else { throw CameraError.permissionDenied }
        try configureIfNeeded()
        if !session.isRunning {
            try start()
            try await Task.sleep(for: .milliseconds(400))
        }
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                self.photoContinuation = continuation
                var settings = AVCapturePhotoSettings()
                if self.photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                }
                settings.flashMode = self.flashMode
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    private func configureIfNeeded() throws {
        guard !isConfigured else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            throw CameraError.unavailable
        }
        session.addInput(input)
        currentInput = input

        guard session.canAddOutput(photoOutput) else {
            session.commitConfiguration()
            throw CameraError.unavailable
        }
        session.addOutput(photoOutput)
        session.commitConfiguration()
        isConfigured = true
    }
}

extension RealCamera: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let result: Result<Data, Error>
        if let error {
            result = .failure(error)
        } else if let data = photo.fileDataRepresentation() {
            result = .success(data)
        } else {
            result = .failure(CameraError.captureFailed)
        }
        Task { @MainActor in
            self.photoContinuation?.resume(with: result)
            self.photoContinuation = nil
        }
    }
}
