import ExpoModulesCore
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Combine

// Performance: Reference-type cache that persists across SwiftUI re-renders.
// Mutating properties here does NOT trigger SwiftUI view updates, which prevents
// infinite re-render loops when caching from inside `body`.
private final class FilterCache {
    var sourceCIImage: CIImage?
    // Performance: Use ObjectIdentifier for UIImage identity, not content hashing.
    // UIImage inherits NSObject.hash which is pointer-based. ObjectIdentifier makes
    // the "same object instance" intent explicit and avoids semantic ambiguity.
    var sourceImageID: ObjectIdentifier?
    var baseCIImage: CIImage?
    var basePropsKey: String = ""
    // Performance: Cache ShineConfig to avoid re-parsing the dictionary on every
    // animation frame. Invalidated only when props.shine changes.
    var shineConfig: ShineConfig?
    var shinePropsKey: [String: Double] = [:]
}

struct ExpoCIFilterView: ExpoSwiftUI.View, ExpoSwiftUI.WithHostingView {
    let props: ExpoCIFilterProps
    @State private var loadedImage: UIImage?
    @State private var shineProgress: Double = 0.0
    @State private var timerCancellable: AnyCancellable?

    // Performance: Removed unused `private let ciContext = CIContext()`.
    // The view already uses SharedCIContext.context for rendering.
    // CIContext creation is expensive (GPU resource allocation). See Apple's
    // "Core Image Programming Guide > Getting the Best Performance".

    // Performance: Reference-type cache held by @State so it survives struct re-creation.
    // Because FilterCache is a class, writing to its properties is invisible to SwiftUI,
    // letting us cache without triggering extra renders.
    @State private var cache = FilterCache()

    private var contentMode: ContentMode {
        switch props.contentFit {
        case "contain":
            return .fit
        case "fill", "scaleDown":
            return .fill
        default:
            return .fill
        }
    }

    var body: some View {
           Group {
               if let img = loadedImage {
                   if let filtered = applyFilters(to: img) {
                       Image(uiImage: filtered)
                           .resizable()
                           .aspectRatio(contentMode: contentMode)
                           .clipped()
                           .cornerRadius(props.borderRadius)
                   } else {
                       Image(uiImage: img)
                           .resizable()
                           .aspectRatio(contentMode: contentMode)
                           .clipped()
                           .cornerRadius(props.borderRadius)
                   }
               } else {
                   ProgressView()
                       .progressViewStyle(CircularProgressViewStyle())
                       .scaleEffect(1.2)
                       .onAppear(perform: loadImage)
               }
           }
           .onAppear { startShineTimerIfNeeded() }
           .onDisappear { stopShineTimer() }
           .onChange(of: props.shine) { newValue in
               if newValue.isEmpty {
                   stopShineTimer()
                   shineProgress = 0.0
               } else {
                   startShineTimerIfNeeded()
               }
           }
       }



    private func loadImage() {
        guard let url = URL(string: props.url) else { return }
        ImagePreloader.shared.preload(url: url) { img in
            loadedImage = img
        }
    }

    private func startShineTimerIfNeeded() {
        guard !props.shine.isEmpty else { return }
        guard timerCancellable == nil else { return }

        let config = ShineConfig(dict: props.shine)
        guard config.speed > 0 else { return }

        timerCancellable = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let increment = (1.0 / 60.0) / config.speed
                shineProgress += increment
                if shineProgress >= 1.0 {
                    shineProgress -= 1.0
                }
            }
    }

    private func stopShineTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    /// Builds a deterministic cache key from all filter props except shine.
    /// When this key matches the cached value, the base filter pipeline is skipped entirely.
    private func baseFilterCacheKey() -> String {
        let parts: [[String: Double]] = [
            props.motionBlur, props.gaussianBlur, props.colorControls,
            props.exposure, props.vibrance, props.gamma, props.hueAdjust,
            props.sharpen, props.vignette, props.maskedVariableBlur,
            props.gradientOverlay, props.outline
        ]
        // Sort dictionary keys for deterministic output regardless of insertion order.
        return parts.map { dict in
            dict.sorted(by: { $0.key < $1.key })
                .map { "\($0.key):\($0.value)" }
                .joined(separator: ",")
        }.joined(separator: "|")
    }

    func applyFilters(to image: UIImage) -> UIImage? {

        guard !props.motionBlur.isEmpty ||
              !props.gaussianBlur.isEmpty ||
              !props.colorControls.isEmpty ||
              !props.exposure.isEmpty ||
              !props.vibrance.isEmpty ||
              !props.gamma.isEmpty ||
              !props.hueAdjust.isEmpty ||
              !props.sharpen.isEmpty ||
              !props.vignette.isEmpty ||
              !props.maskedVariableBlur.isEmpty ||
              !props.gradientOverlay.isEmpty ||
              !props.outline.isEmpty ||
              !props.shine.isEmpty else {
            return nil
        }

        // Performance: Cache the UIImage -> CIImage conversion.
        // During shine animation the same UIImage object is passed every frame.
        // ObjectIdentifier checks instance identity (same pointer), which is correct
        // because ImagePreloader.shared returns the same cached UIImage instance.
        let imageID = ObjectIdentifier(image)
        let ciImage: CIImage
        if imageID == cache.sourceImageID, let cached = cache.sourceCIImage {
            ciImage = cached
        } else {
            guard let converted = CIImage(image: image) else { return nil }
            ciImage = converted
            cache.sourceCIImage = converted
            cache.sourceImageID = imageID
            // Source image changed, so the base filtered result is stale.
            cache.baseCIImage = nil
            cache.basePropsKey = ""
        }

        let originalExtent = ciImage.extent

        // Performance: Cache the base-filtered CIImage (everything except shine).
        // During shine animation, only shineProgress changes per frame. Without this cache,
        // the full pipeline (including expensive CIMorphologyGradient in outline) would run
        // 60 times per second. With the cache, only the lightweight shine pass runs per frame.
        let currentBaseKey = baseFilterCacheKey()
        let baseCIImage: CIImage

        if currentBaseKey == cache.basePropsKey, let cached = cache.baseCIImage {
            // Cache hit: skip the entire base filter pipeline.
            baseCIImage = cached
        } else {
            // Cache miss: recompute all base filters and store the result.
            var currentImage = ciImage
            let configs = FilterConfigurations(from: props)

            if !props.motionBlur.isEmpty {
                currentImage = applyMotionBlur(to: currentImage, config: configs.motionBlur)
            }
            if !props.gaussianBlur.isEmpty {
                currentImage = applyGaussianBlur(to: currentImage, config: configs.gaussianBlur)
            }
            if !props.colorControls.isEmpty {
                currentImage = applyColorControls(to: currentImage, config: configs.colorControls)
            }
            if !props.exposure.isEmpty {
                currentImage = applyExposure(to: currentImage, config: configs.exposure)
            }
            if !props.vibrance.isEmpty {
                currentImage = applyVibrance(to: currentImage, config: configs.vibrance)
            }
            if !props.gamma.isEmpty {
                currentImage = applyGamma(to: currentImage, config: configs.gamma)
            }
            if !props.hueAdjust.isEmpty {
                currentImage = applyHueAdjust(to: currentImage, config: configs.hueAdjust)
            }
            if !props.sharpen.isEmpty {
                currentImage = applySharpen(to: currentImage, config: configs.sharpen)
            }
            if !props.vignette.isEmpty {
                currentImage = applyVignette(to: currentImage, config: configs.vignette)
            }
            if !props.maskedVariableBlur.isEmpty {
                currentImage = applyMaskedVariableBlur(to: currentImage, config: configs.maskedVariableBlur)
            }
            if !props.gradientOverlay.isEmpty {
                currentImage = applyGradientOverlay(to: currentImage, config: configs.gradientOverlay)
            }
            if !props.outline.isEmpty {
                currentImage = applyOutline(to: currentImage, config: configs.outline)
            }

            // Crop after base filters to prevent extent expansion from blur filters.
            currentImage = currentImage.cropped(to: originalExtent)

            // Performance: Rasterize the base CIImage into a bitmap-backed CIImage.
            // CIImage is lazy; without this, the entire filter graph would be re-evaluated
            // every frame when shine composites on top. Rasterizing here means the cached
            // result is a flat bitmap, making subsequent shine frames O(shine) not O(all).
            if let cgBase = SharedCIContext.context.createCGImage(currentImage, from: originalExtent) {
                baseCIImage = CIImage(cgImage: cgBase)
            } else {
                baseCIImage = currentImage
            }

            cache.baseCIImage = baseCIImage
            cache.basePropsKey = currentBaseKey
        }

        // Performance: Only the shine filter runs per animation frame.
        // All other filters are served from the rasterized cache above.
        var finalImage = baseCIImage
        if !props.shine.isEmpty {
            // Performance: Reuse cached ShineConfig instead of re-parsing the dictionary
            // on every animation frame (60 times per second).
            let shineConfig: ShineConfig
            if props.shine == cache.shinePropsKey, let cached = cache.shineConfig {
                shineConfig = cached
            } else {
                shineConfig = ShineConfig(dict: props.shine)
                cache.shineConfig = shineConfig
                cache.shinePropsKey = props.shine
            }
            finalImage = applyShine(to: finalImage, config: shineConfig, progress: shineProgress)
            finalImage = finalImage.cropped(to: originalExtent)
        }

        guard let cgImage = SharedCIContext.context.createCGImage(finalImage, from: originalExtent) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}