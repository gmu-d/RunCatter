/*
 Color+Extension.swift
 UserInterface

 Created by Takuto Nakamura on 2026/08/31.
 Copyright 2026 Kyome22 (Takuto Nakamura)

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import SwiftUI

extension Color {
    init?(hex: String?) {
        guard let cgColor = hex.flatMap(CGColor.from(hex:)) else { return nil }
        self.init(cgColor: cgColor)
    }

    var hex: String? {
        guard let cgColor = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let red = Int(round(cgColor.redComponent * 255.0))
        let green = Int(round(cgColor.greenComponent * 255.0))
        let blue = Int(round(cgColor.blueComponent * 255.0))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
