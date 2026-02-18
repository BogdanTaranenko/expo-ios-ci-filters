//
//  FilterConfiguration.swift
//  Pods
//
//  Created by rit3zh CX on 8/13/25.
//

struct FilterConfigurations {
    let motionBlur: MotionBlurConfig
    let colorControls: ColorControlsConfig
    let gaussianBlur: GaussianBlurConfig
    let exposure: ExposureConfig
    let vibrance: VibranceConfig
    let gamma: GammaConfig
    let hueAdjust: HueAdjustConfig
    let sharpen: SharpenConfig
    let vignette: VignetteConfig
    let maskedVariableBlur: MaskedVariableBlurConfig
    let gradientOverlay: GradientOverlayConfig
    let outline: OutlineConfig

    init(from props: ExpoCIFilterProps) {
        self.motionBlur = MotionBlurConfig(dict: props.motionBlur)
        self.colorControls = ColorControlsConfig(dict: props.colorControls)
        self.gaussianBlur = GaussianBlurConfig(dict: props.gaussianBlur)
        self.exposure = ExposureConfig(dict: props.exposure)
        self.vibrance = VibranceConfig(dict: props.vibrance)
        self.gamma = GammaConfig(dict: props.gamma)
        self.hueAdjust = HueAdjustConfig(dict: props.hueAdjust)
        self.sharpen = SharpenConfig(dict: props.sharpen)
        self.vignette = VignetteConfig(dict: props.vignette)
        self.maskedVariableBlur = MaskedVariableBlurConfig(dict: props.maskedVariableBlur)
        self.gradientOverlay = GradientOverlayConfig(dict: props.gradientOverlay)
        self.outline = OutlineConfig(dict: props.outline)
    }
}
