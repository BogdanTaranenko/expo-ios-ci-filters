//
//  ShineConfig.swift
//  Pods
//

struct ShineConfig: FilterConfig {
    var width: Double = 2.0
    var speed: Double = 2.0
    var spread: Double = 0.15
    var intensity: Double = 1.0
    var angle: Double = 0.785
    var colorRed: Double = 1.0
    var colorGreen: Double = 1.0
    var colorBlue: Double = 1.0
    var colorAlpha: Double = 0.8

    init(dict: [String: Double]) {
        self.width = dict["width"] ?? 2.0
        self.speed = dict["speed"] ?? 2.0
        self.spread = dict["spread"] ?? 0.15
        self.intensity = dict["intensity"] ?? 1.0
        self.angle = dict["angle"] ?? 0.785
        self.colorRed = dict["colorRed"] ?? 1.0
        self.colorGreen = dict["colorGreen"] ?? 1.0
        self.colorBlue = dict["colorBlue"] ?? 1.0
        self.colorAlpha = dict["colorAlpha"] ?? 0.8
    }
}
