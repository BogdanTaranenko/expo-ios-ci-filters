//
//  OutlineConfig.swift
//  Pods
//
//  Created by rit3zh CX on 8/13/25.
//

struct OutlineConfig: FilterConfig {
    var width: Double = 2.0
    var colorRed: Double = 0.0
    var colorGreen: Double = 0.0
    var colorBlue: Double = 0.0
    var colorAlpha: Double = 1.0

    init(dict: [String: Double]) {
        self.width = dict["width"] ?? 2.0
        self.colorRed = dict["colorRed"] ?? 0.0
        self.colorGreen = dict["colorGreen"] ?? 0.0
        self.colorBlue = dict["colorBlue"] ?? 0.0
        self.colorAlpha = dict["colorAlpha"] ?? 1.0
    }
}