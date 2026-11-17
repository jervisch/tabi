import Foundation
import AVFoundation
import UIKit

enum CameraError: Error, Equatable {
    case permissionDenied
    case unavailable
    case captureFailed
}

@MainActor
protocol CameraCapturing: AnyObject {
    var authorization: AVAuthorizationStatus { get }
    var session: AVCaptureSession { get }
    func requestPermission() async -> Bool
    func start() throws
    func stop()
    func capturePhoto() async throws -> Data
}
