# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`expo-ios-ci-filters` is an **iOS-only** Expo module that exposes Apple's Core Image filters to React Native. It bridges native iOS Core Image functionality with a TypeScript/React interface, enabling GPU-accelerated image filtering in Expo apps.

**Key constraint**: iOS-only. No Android support (Core Image is iOS-specific).

## Development Commands

### Building the Module
```bash
pnpm run build           # Build the TypeScript code → build/
pnpm run clean           # Clean build artifacts
pnpm run lint            # Run ESLint
pnpm run test            # Run tests
pnpm run prepare         # Prepare module for publishing
```

### iOS Development
```bash
pnpm run open:ios        # Open iOS project in Xcode (example/ios)
cd ios && pod install    # Install CocoaPods dependencies
```

### Example App
```bash
cd example
pnpm start               # Start Expo dev server
pnpm ios                 # Run on iOS simulator
```

## Architecture

### Three-Layer System

1. **Swift Native Layer** (`/ios/`)
   - `ExpoIOSCIFiltersView.swift`: Main SwiftUI view that applies filters
   - `filters/Filters.swift`: Individual filter implementations (11 global functions)
   - `config/`: Filter configuration structs (one per filter type)
   - `core/FilterConfiguration.swift`: Aggregates all filter configs
   - `context/SharedCIContext.swift`: Singleton CIContext for rendering
   - `ImagePreLoader.swift`: Handles async image loading

2. **TypeScript Bridge Layer** (`/src/`)
   - `react-view/CIFilterReactView.tsx`: React component wrapper (`CIFilterImage`)
   - `view/NativeFilterView.ios.tsx`: Expo native view binding
   - `typings/`: TypeScript interfaces for filter props
   - `presets/`: Pre-configured filter combinations

3. **Expo Module Integration**
   - Uses Expo Modules API (ExpoModulesCore, ExpoSwiftUI)
   - `expo-module.config.json`: Module configuration
   - `ExpoIOSCIFilterProps.swift`: Defines @Field properties for React → Swift prop passing

### Filter Pipeline

**React → Swift → Core Image**

1. User passes filter props to `<CIFilterImage />` (e.g., `motionBlur={{ radius: 20, angle: 0 }}`)
2. `CIFilterReactView.tsx` normalizes props and passes to native view
3. `ExpoCIFilterView.applyFilters()` processes filters sequentially:
   - Checks if each filter dict is non-empty
   - Applies filter using global functions from `Filters.swift`
   - Each filter returns modified CIImage (or original on failure)
   - Chains filters: `image → blur → colorControls → exposure → ...`
   - Crops to original extent to prevent edge artifacts
4. `SharedCIContext.context.createCGImage()` renders final result
5. Converts to UIImage and displays in SwiftUI `Image` view

### Filter Configuration Pattern

Each filter has a corresponding config struct in `/ios/config/`:

```swift
// Example: MotionBlurConfig.swift
struct MotionBlurConfig: FilterConfig {
    var radius: Double = 0
    var angle: Double = 0

    init(dict: [String: Double]) {
        self.radius = dict["radius"] ?? 0
        self.angle = dict["angle"] ?? 0
    }
}
```

**Critical**: Configs are initialized from `[String: Double]` dictionaries passed from React. All filter params must be representable as `Double`.

## Adding New Filters

To add a new Core Image filter:

1. Create config struct in `/ios/config/YourFilterConfig.swift`:
   ```swift
   struct YourFilterConfig: FilterConfig {
       var param: Double = defaultValue
       init(dict: [String: Double]) { /* parse dict */ }
   }
   ```

2. Add filter function to `/ios/filters/Filters.swift`:
   ```swift
   func applyYourFilter(to image: CIImage, config: YourFilterConfig) -> CIImage {
       let filter = CIFilter.yourFilter()
       filter.inputImage = image
       filter.param = Float(config.param)
       return filter.outputImage ?? image
   }
   ```

3. Update `FilterConfigurations` in `/ios/core/FilterConfiguration.swift`:
   ```swift
   struct FilterConfigurations {
       let yourFilter: YourFilterConfig
       // ... existing filters

       init(from props: ExpoCIFilterProps) {
           self.yourFilter = YourFilterConfig(dict: props.yourFilter)
           // ... existing inits
       }
   }
   ```

4. Add property to `ExpoCIFilterProps.swift`:
   ```swift
   @Field var yourFilter: [String: Double] = [:]
   ```

5. Apply in filter chain in `ExpoIOSCIFiltersView.swift`:
   ```swift
   if !props.yourFilter.isEmpty {
       currentImage = applyYourFilter(to: currentImage, config: configs.yourFilter)
   }
   ```

6. Add TypeScript types in `/src/typings/react-prop/react-prop.ios.ts`

7. Export from `/src/index.ts`

## Available Filters

The module includes the following Core Image filters:

1. **Blur Filters**: `motionBlur`, `gaussianBlur`, `maskedVariableBlur`
2. **Color Adjustments**: `colorControls`, `exposure`, `vibrance`, `gamma`, `hueAdjust`
3. **Enhancement Filters**: `sharpen`, `vignette`
4. **Overlay Filters**: `gradientOverlay`
5. **Edge Detection**: `outline` - Adds configurable colored outline to image edges

### Outline Filter

The `outline` filter detects edges and applies a colored outline:

**Parameters** (all optional):
- `width`: Outline thickness (0-10, default: 2.0)
- `colorRed`: Red channel (0-1, default: 0.0)
- `colorGreen`: Green channel (0-1, default: 0.0)
- `colorBlue`: Blue channel (0-1, default: 0.0)
- `colorAlpha`: Alpha/opacity (0-1, default: 1.0)

**Example Usage**:
```typescript
<CIFilterImage
  url="https://example.com/image.jpg"
  outline={{
    width: 3,
    colorRed: 1.0,
    colorGreen: 0.0,
    colorBlue: 0.0,
    colorAlpha: 1.0
  }}
/>
```

**Implementation Details**:
- Uses `CIEdges` filter for edge detection
- Edge intensity controlled by `width` parameter
- Edges are inverted and masked with specified color
- Outline composited over original image using `sourceOverCompositing`

## Important Implementation Details

### Coordinate Normalization
Filters like `maskedVariableBlur` and `gradientOverlay` use **normalized coordinates** (0.0-1.0):
- `point0X`, `point0Y`, `point1X`, `point1Y` are multiplied by image dimensions in Swift
- This ensures filter configs work across different image sizes

### Filter Order Matters
Filters are applied **sequentially** in the order defined in `ExpoIOSCIFiltersView.applyFilters()`. Order affects final output (e.g., blur before color adjust vs. after).

### Extent Cropping
`currentImage.cropped(to: originalExtent)` is critical. Some filters (especially blur) expand the image bounds. Cropping prevents cumulative expansion across multiple filters.

### Shared CIContext
`SharedCIContext.context` is a singleton to avoid recreating expensive CIContext instances. All filter rendering uses this shared context.

### Image Loading
`ImagePreloader.shared.preload()` handles async URL fetching. View shows `ProgressView` until image loads.

## Common Gotchas

- **iOS-only**: Never implement Android equivalents without understanding Core Image has no Android counterpart
- **Filter dictionaries must be [String: Double]**: No other types supported in current architecture
- **Empty dict check**: Always check `!props.filterName.isEmpty` before applying
- **Angle units**: Core Image uses **radians**, not degrees (document this in TypeScript interfaces)
- **Default values matter**: Config structs use defaults when keys missing from React props

## Testing Strategy

When testing new filters:
1. Test with example app (`cd example && pnpm ios`)
2. Verify filter appears in real-time as props change
3. Test filter chaining (multiple filters at once)
4. Test edge cases (empty configs, extreme values)
5. Verify no performance regression (filters run on GPU)

## Dependencies

- **Expo SDK 53+** required
- **iOS 13.0+** (defined in SharedCIContext availability checks)
- **Swift 5+** (Expo Modules API)
- **CocoaPods** for dependency management
