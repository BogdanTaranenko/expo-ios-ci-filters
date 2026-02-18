import ExpoModulesCore
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Combine

struct ExpoCIFilterView: ExpoSwiftUI.View, ExpoSwiftUI.WithHostingView {
    let props: ExpoCIFilterProps
    @State private var loadedImage: UIImage?
    @State private var shineProgress: Double = 0.0
    @State private var timerCancellable: AnyCancellable?

    private let ciContext = CIContext()


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

           guard let ciImage = CIImage(image: image) else { return nil }


           let originalExtent = ciImage.extent
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
          if !props.shine.isEmpty {
              currentImage = applyShine(to: currentImage, config: configs.shine, progress: shineProgress)
          }

           currentImage = currentImage.cropped(to: originalExtent)


           guard let cgImage = SharedCIContext.context.createCGImage(currentImage, from: originalExtent) else {
               return nil
           }

           return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
       }
}
