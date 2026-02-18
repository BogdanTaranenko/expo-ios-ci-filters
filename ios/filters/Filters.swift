//
//  Filters.swift
//  Pods
//
//  Created by rit3zh CX on 8/13/25.
//

 func applyMotionBlur(to image: CIImage, config: MotionBlurConfig) -> CIImage {
        guard config.radius > 0 else { return image }
        
        let filter = CIFilter.motionBlur()
        filter.inputImage = image
        filter.radius = Float(config.radius)
        filter.angle = Float(config.angle)
        return filter.outputImage ?? image
    }

     func applyGaussianBlur(to image: CIImage, config: GaussianBlurConfig) -> CIImage {
        guard config.radius > 0 else { return image }
        
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = image
        filter.radius = Float(config.radius)
        return filter.outputImage ?? image
    }

     func applyColorControls(to image: CIImage, config: ColorControlsConfig) -> CIImage {
        guard config.brightness != 0 || config.contrast != 1 || config.saturation != 1 else { return image }
        
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.brightness = Float(config.brightness)
        filter.contrast = Float(config.contrast)
        filter.saturation = Float(config.saturation)
        return filter.outputImage ?? image
    }

     func applyExposure(to image: CIImage, config: ExposureConfig) -> CIImage {
        guard config.ev != 0 else { return image }
        
        let filter = CIFilter.exposureAdjust()
        filter.inputImage = image
        filter.ev = Float(config.ev)
        return filter.outputImage ?? image
    }

     func applyVibrance(to image: CIImage, config: VibranceConfig) -> CIImage {
        guard config.amount != 0 else { return image }
        
        let filter = CIFilter.vibrance()
        filter.inputImage = image
        filter.amount = Float(config.amount)
        return filter.outputImage ?? image
    }

     func applyGamma(to image: CIImage, config: GammaConfig) -> CIImage {
        guard config.power != 1 else { return image }
        
        let filter = CIFilter.gammaAdjust()
        filter.inputImage = image
        filter.power = Float(config.power)
        return filter.outputImage ?? image
    }

     func applyHueAdjust(to image: CIImage, config: HueAdjustConfig) -> CIImage {
        guard config.angle != 0 else { return image }
        
        let filter = CIFilter.hueAdjust()
        filter.inputImage = image
        filter.angle = Float(config.angle)
        return filter.outputImage ?? image
    }

     func applySharpen(to image: CIImage, config: SharpenConfig) -> CIImage {
        guard config.sharpness != 0 else { return image }
        
        let filter = CIFilter.sharpenLuminance()
        filter.inputImage = image
        filter.sharpness = Float(config.sharpness)
        return filter.outputImage ?? image
    }

     func applyVignette(to image: CIImage, config: VignetteConfig) -> CIImage {
        guard config.intensity != 0 else { return image }
        
        let filter = CIFilter.vignette()
        filter.inputImage = image
        filter.intensity = Float(config.intensity)
        filter.radius = Float(config.radius)
        return filter.outputImage ?? image
    }

func applyMaskedVariableBlur(to image: CIImage, config: MaskedVariableBlurConfig) -> CIImage {
        guard config.radius > 0 else { return image }
        
        let filter = CIFilter.maskedVariableBlur()
        filter.inputImage = image
        
        
        let mask = CIFilter.smoothLinearGradient()
        
        
        mask.color0 = CIColor(red: config.color0Alpha, green: config.color0Alpha, blue: config.color0Alpha, alpha: 1)
        mask.color1 = CIColor(red: config.color1Alpha, green: config.color1Alpha, blue: config.color1Alpha, alpha: 1)
        
        
        let imageHeight = image.extent.height
        let imageWidth = image.extent.width
        
        mask.point0 = CGPoint(
            x: config.point0X * imageWidth,
            y: config.point0Y * imageHeight
        )
        mask.point1 = CGPoint(
            x: config.point1X * imageWidth,
            y: config.point1Y * imageHeight
        )
        
        filter.mask = mask.outputImage
        filter.radius = Float(config.radius)
        
        return filter.outputImage ?? image
    }

func applyGradientOverlay(to image: CIImage, config: GradientOverlayConfig) -> CIImage {


    guard config.color0Alpha > 0 || config.color1Alpha > 0 else { return image }

        let gradient = CIFilter.smoothLinearGradient()
        gradient.color0 = CIColor(
            red: config.color0Red,
            green: config.color0Green,
            blue: config.color0Blue,
            alpha: config.color0Alpha
        )
        gradient.color1 = CIColor(
            red: config.color1Red,
            green: config.color1Green,
            blue: config.color1Blue,
            alpha: config.color1Alpha
        )


        let imageHeight = image.extent.height
        let imageWidth = image.extent.width

        gradient.point0 = CGPoint(
            x: config.point0X * imageWidth,
            y: config.point0Y * imageHeight
        )
        gradient.point1 = CGPoint(
            x: config.point1X * imageWidth,
            y: config.point1Y * imageHeight
        )

        guard let gradientImage = gradient.outputImage else { return image }


        let blendFilter: CIFilter
        switch config.blendMode {
        case "multiply":
            blendFilter = CIFilter.multiplyBlendMode()
        case "overlay":
            blendFilter = CIFilter.overlayBlendMode()
        case "softLight":
            blendFilter = CIFilter.softLightBlendMode()
        case "hardLight":
            blendFilter = CIFilter.hardLightBlendMode()
        case "screen":
            blendFilter = CIFilter.screenBlendMode()
        default:
            blendFilter = CIFilter.sourceAtopCompositing()
        }

        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(gradientImage, forKey: kCIInputImageKey)

        return blendFilter.outputImage ?? image
    }

func applyShine(to image: CIImage, config: ShineConfig, progress: Double) -> CIImage {
    let extent = image.extent

    // Step 1: Object mask from alpha channel
    guard let alphaMaskFilter = CIFilter(name: "CIColorMatrix") else { return image }
    alphaMaskFilter.setValue(image, forKey: kCIInputImageKey)
    alphaMaskFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputRVector")
    alphaMaskFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputGVector")
    alphaMaskFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputBVector")
    alphaMaskFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
    guard let alphaImage = alphaMaskFilter.outputImage else { return image }

    // Use edges-only mask or full object mask
    let objectMask: CIImage
    if config.edgesOnly > 0 && config.width > 0 {
        guard let edgeFilter = CIFilter(name: "CIMorphologyGradient") else { return image }
        edgeFilter.setValue(alphaImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(config.width, forKey: "inputRadius")
        guard let edgeMask = edgeFilter.outputImage else { return image }
        objectMask = edgeMask
    } else {
        objectMask = alphaImage.cropped(to: extent)
    }

    // Step 2: Sweeping band gradient positioned by progress + angle
    let diagonal = sqrt(extent.width * extent.width + extent.height * extent.height)
    let cosA = CGFloat(cos(config.angle))
    let sinA = CGFloat(sin(config.angle))

    let centerX = extent.midX
    let centerY = extent.midY

    let totalSweep = diagonal * 2.0
    let bandCenter = -diagonal * 0.5 + totalSweep * CGFloat(progress)
    let halfSpread = diagonal * CGFloat(config.spread) * 0.5

    let p0x = centerX + cosA * (bandCenter - halfSpread)
    let p0y = centerY + sinA * (bandCenter - halfSpread)
    let p1x = centerX + cosA * (bandCenter + halfSpread)
    let p1y = centerY + sinA * (bandCenter + halfSpread)

    let bandWhite = CIColor(red: 1, green: 1, blue: 1, alpha: 1)
    let bandBlack = CIColor(red: 0, green: 0, blue: 0, alpha: 1)

    let grad1 = CIFilter.smoothLinearGradient()
    grad1.point0 = CGPoint(x: p0x, y: p0y)
    grad1.point1 = CGPoint(x: centerX + cosA * bandCenter, y: centerY + sinA * bandCenter)
    grad1.color0 = bandBlack
    grad1.color1 = bandWhite
    guard let gradImg1 = grad1.outputImage?.cropped(to: extent) else { return image }

    let grad2 = CIFilter.smoothLinearGradient()
    grad2.point0 = CGPoint(x: centerX + cosA * bandCenter, y: centerY + sinA * bandCenter)
    grad2.point1 = CGPoint(x: p1x, y: p1y)
    grad2.color0 = bandWhite
    grad2.color1 = bandBlack
    guard let gradImg2 = grad2.outputImage?.cropped(to: extent) else { return image }

    guard let multiplyFilter = CIFilter(name: "CIMultiplyBlendMode") else { return image }
    multiplyFilter.setValue(gradImg1, forKey: kCIInputImageKey)
    multiplyFilter.setValue(gradImg2, forKey: kCIInputBackgroundImageKey)
    guard let bandImage = multiplyFilter.outputImage else { return image }

    // Step 3: Mask band to object shape
    guard let maskBandFilter = CIFilter(name: "CIMultiplyBlendMode") else { return image }
    maskBandFilter.setValue(bandImage, forKey: kCIInputImageKey)
    maskBandFilter.setValue(objectMask, forKey: kCIInputBackgroundImageKey)
    guard let shineMask = maskBandFilter.outputImage else { return image }

    // Step 4: Generate shine color and blend onto original
    guard let colorFilter = CIFilter(name: "CIConstantColorGenerator") else { return image }
    colorFilter.setValue(
        CIColor(
            red: config.colorRed,
            green: config.colorGreen,
            blue: config.colorBlue,
            alpha: config.colorAlpha * config.intensity
        ),
        forKey: kCIInputColorKey
    )
    guard let colorImage = colorFilter.outputImage?.cropped(to: extent) else { return image }

    guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return image }
    blendFilter.setValue(colorImage, forKey: kCIInputImageKey)
    blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
    blendFilter.setValue(shineMask, forKey: kCIInputMaskImageKey)
    guard let blendedOutput = blendFilter.outputImage else { return image }

    // Step 5: Clip to original alpha so shine doesn't leak into transparent areas
    guard let sourceInFilter = CIFilter(name: "CISourceInCompositing") else { return image }
    sourceInFilter.setValue(blendedOutput, forKey: kCIInputImageKey)
    sourceInFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
    guard let output = sourceInFilter.outputImage else { return image }

    return output
}

func applyOutline(to image: CIImage, config: OutlineConfig) -> CIImage {
    guard config.width > 0 else { return image }
    
    let context = CIContext(options: nil)
    let expandedExtent = image.extent

    // Extract the alpha channel
    guard let alphaMaskFilter = CIFilter(name: "CIColorMatrix") else { return image }
    alphaMaskFilter.setValue(image, forKey: kCIInputImageKey)
    alphaMaskFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputRVector")
    alphaMaskFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputGVector")
    alphaMaskFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputBVector")
    alphaMaskFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")

    guard let alphaImage = alphaMaskFilter.outputImage else { return image }

    // Create outline with morphology
    guard let edgeFilter = CIFilter(name: "CIMorphologyGradient") else { return image }
    edgeFilter.setValue(alphaImage, forKey: kCIInputImageKey)
    edgeFilter.setValue(config.width, forKey: "inputRadius")
    guard let edgeMaskImage = edgeFilter.outputImage else { return image }

    // Generate colored outline
    guard let colorFilter = CIFilter(name: "CIConstantColorGenerator") else { return image }
    colorFilter.setValue(
        CIColor(
            red: config.colorRed,
            green: config.colorGreen,
            blue: config.colorBlue,
            alpha: config.colorAlpha
        ),
        forKey: kCIInputColorKey
    )
    guard let colorImage = colorFilter.outputImage?.cropped(to: expandedExtent) else { return image }

    // Mask color with the outline
    guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return image }
    blendFilter.setValue(colorImage, forKey: kCIInputImageKey)
    blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
    blendFilter.setValue(edgeMaskImage, forKey: kCIInputMaskImageKey)
    guard let outputImage = blendFilter.outputImage else { return image }
    
    return outputImage
}
