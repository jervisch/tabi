import Foundation
import CoreImage
import UIKit

/// Composable TABi film look — intentionally photographic, not obviously filtered.
struct TABiFilmProcessor {
    var saturation: Double = 0.85
    var contrast: Double = 1.06
    var blackLift: Double = 0.04
    var grainOpacity: Double = 0.05
    var highlightWarmth: Double = 0.08
    var shadowCoolness: Double = 0.06
    var halationStrength: Double = 0.04

    func process(_ data: Data) throws -> Data {
        guard let image = CIImage(data: data) else {
            throw CameraError.captureFailed
        }
        var output = image

        // 1) gentle contrast
        output = output.applyingFilter("CIColorControls", parameters: [
            kCIInputBrightnessKey: 0.01,
            kCIInputContrastKey: contrast,
            kCIInputSaturationKey: saturation
        ])

        // 2) split tone: warm highlights / cool shadows via overlay tint + soft light
        output = applySplitTone(to: output)

        // 3) lifted blacks
        output = liftBlacks(output)

        // 4) grain
        output = applyGrain(to: output)

        // 5) soft highlight rolloff + hint of halation
        output = applyHighlightRolloff(to: output)

        let context = CIContext(options: [.cacheIntermediates: false])
        guard let cg = context.createCGImage(output, from: output.extent) else {
            throw CameraError.captureFailed
        }
        let uiImage = UIImage(cgImage: cg)
        guard let jpeg = uiImage.jpegData(compressionQuality: 0.92) else {
            throw CameraError.captureFailed
        }
        return jpeg
    }

    private func applySplitTone(to image: CIImage) -> CIImage {
        // Warm overlay on highlights: multiply-ish via additive yellow in bright areas
        let warm = CIImage(color: CIColor(red: 1 + highlightWarmth, green: 1 + highlightWarmth * 0.5, blue: 1 - highlightWarmth * 0.3))
            .cropped(to: image.extent)
        var result = image.applyingFilter("CISoftLightBlendMode", parameters: [kCIInputBackgroundImageKey: warm])

        let cool = CIImage(color: CIColor(red: 1 - shadowCoolness * 0.5, green: 1, blue: 1 + shadowCoolness))
            .cropped(to: image.extent)
        // Screen a touch of cool into shadows via source-over low opacity equivalent:
        result = result.applyingFilter("CIPlusBlendMode", parameters: [kCIInputBackgroundImageKey: cool])
            .applyingFilter("CIColorControls", parameters: [kCIInputBrightnessKey: -shadowCoolness * 0.15])
        return result
    }

    private func liftBlacks(_ image: CIImage) -> CIImage {
        // Raise minimum output: approximate with gamma + brightness floor
        image.applyingFilter("CIGammaAdjust", parameters: ["inputPower": 1.0 / (1.0 + blackLift * 4)])
            .applyingFilter("CIColorControls", parameters: [kCIInputBrightnessKey: blackLift * 0.35])
    }

    private func applyGrain(to image: CIImage) -> CIImage {
        let noise = CIFilter(name: "CIRandomGenerator")?.outputImage?
            .cropped(to: image.extent)
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 0, z: 0, w: grainOpacity),
                "inputGVector": CIVector(x: 0, y: 0, z: 0, w: grainOpacity),
                "inputBVector": CIVector(x: 0, y: 0, z: 0, w: grainOpacity),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: 0.5, y: 0.5, z: 0.5, w: 0)
            ])
        guard let noise else { return image }
        return image.applyingFilter("CIOverlayBlendMode", parameters: [kCIInputBackgroundImageKey: noise])
    }

    private func applyHighlightRolloff(to image: CIImage) -> CIImage {
        let blurred = image.applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 12])
        let halation = image.applyingFilter("CIAdditionCompositing", parameters: [kCIInputBackgroundImageKey: blurred])
            .applyingFilter("CIColorControls", parameters: [kCIInputBrightnessKey: -0.08])
        return image.applyingFilter("CIOverlayBlendMode", parameters: [kCIInputBackgroundImageKey: halation])
            .applyingFilter("CIColorControls", parameters: [kCIInputBrightnessKey: 0.005])
    }
}
