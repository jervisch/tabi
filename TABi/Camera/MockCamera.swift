import Foundation
import AVFoundation

final class MockCamera: CameraCapturing {
    var authorization: AVAuthorizationStatus
    let session = AVCaptureSession()
    var fixtureData: Data
    private(set) var captureCount = 0
    private(set) var started = false

    init(
        authorization: AVAuthorizationStatus = .authorized,
        fixtureData: Data = MockCamera.defaultFixture
    ) {
        self.authorization = authorization
        self.fixtureData = fixtureData
    }

    func requestPermission() async -> Bool {
        if authorization == .notDetermined {
            authorization = .authorized
        }
        return authorization == .authorized
    }

    func start() throws {
        guard authorization == .authorized else { throw CameraError.permissionDenied }
        started = true
    }

    func stop() {
        started = false
    }

    func capturePhoto() async throws -> Data {
        guard authorization == .authorized else { throw CameraError.permissionDenied }
        captureCount += 1
        return fixtureData
    }

    /// 1x1 red PNG
    static let defaultFixture = Data([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
        0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
        0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
        0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
    ])
}
