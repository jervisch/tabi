import Foundation
import Photos

@MainActor
protocol PhotoLibraryExporting: AnyObject {
    func requestAddPermission() async -> Bool
    func export(jpegData: Data) async throws
}

@MainActor
final class RealPhotoLibraryExporter: PhotoLibraryExporting {
    func requestAddPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
        default:
            return false
        }
    }

    func export(jpegData: Data) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            request.addResource(with: .photo, data: jpegData, options: options)
        }
    }
}
