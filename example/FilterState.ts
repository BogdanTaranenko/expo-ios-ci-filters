import type {
  MotionBlurConfig,
  ColorControlsConfig,
  GaussianBlurConfig,
  ExposureConfig,
  VibranceConfig,
  GammaConfig,
  HueAdjustConfig,
  SharpenConfig,
  VignetteConfig,
  MaskedVariableBlurConfig,
  GradientOverlayConfig,
  OutlineConfig,
  ShineConfig,
} from "expo-ios-ci-filters";

export interface FilterState {
  motionBlur: MotionBlurConfig;
  colorControls: ColorControlsConfig;
  gaussianBlur: GaussianBlurConfig;
  exposure: ExposureConfig;
  vibrance: VibranceConfig;
  gamma: GammaConfig;
  hueAdjust: HueAdjustConfig;
  sharpen: SharpenConfig;
  vignette: VignetteConfig;
  maskedVariableBlur: MaskedVariableBlurConfig;
  gradientOverlay: GradientOverlayConfig;
  outline: OutlineConfig;
  shine: ShineConfig;
}
