//
//  ExpoIOSCIFilterProps.swift
//  Pods
//
//  Created by rit3zh CX on 8/11/25.
//

import ExpoModulesCore
import SwiftUI

class ExpoCIFilterProps: ExpoSwiftUI.ViewProps {
    @Field var url: String = ""
     @Field var contentFit: String = "cover"
     @Field var borderRadius: Double = 0
     @Field var motionBlur: [String: Double] = [:]
     @Field var colorControls: [String: Double] = [:]
     @Field var gaussianBlur: [String: Double] = [:]
     @Field var exposure: [String: Double] = [:]
     @Field var vibrance: [String: Double] = [:]
     @Field var gamma: [String: Double] = [:]
     @Field var hueAdjust: [String: Double] = [:]
     @Field var sharpen: [String: Double] = [:]
     @Field var vignette: [String: Double] = [:]
     @Field var maskedVariableBlur: [String: Double] = [:]
     @Field var gradientOverlay: [String: Double] = [:]
     @Field var outline: [String: Double] = [:]
     @Field var shine: [String: Double] = [:]
}
