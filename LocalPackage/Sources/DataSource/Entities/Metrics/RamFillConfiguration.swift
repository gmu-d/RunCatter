/*
 RamFillConfiguration.swift
 DataSource

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

public struct RamFillConfiguration: Codable, Sendable, Equatable {
    public var isVisible: Bool
    public var showsOverloadOnly: Bool
    public var lowThreshold: Int
    public var highThreshold: Int
    public var lowColorHex: String?
    public var normalColorHex: String?
    public var highColorHex: String?

    public init(
        isVisible: Bool = true,
        showsOverloadOnly: Bool = false,
        lowThreshold: Int,
        highThreshold: Int,
        lowColorHex: String?,
        normalColorHex: String?,
        highColorHex: String?
    ) {
        self.isVisible = isVisible
        self.showsOverloadOnly = showsOverloadOnly
        self.lowThreshold = lowThreshold
        self.highThreshold = highThreshold
        self.lowColorHex = lowColorHex
        self.normalColorHex = normalColorHex
        self.highColorHex = highColorHex
    }

    private enum CodingKeys: String, CodingKey {
        case isVisible, showsOverloadOnly, lowThreshold, highThreshold
        case lowColorHex, normalColorHex, highColorHex
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isVisible = try container.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
        showsOverloadOnly = try container.decodeIfPresent(Bool.self, forKey: .showsOverloadOnly) ?? false
        lowThreshold = try container.decode(Int.self, forKey: .lowThreshold)
        highThreshold = try container.decode(Int.self, forKey: .highThreshold)
        lowColorHex = try container.decodeIfPresent(String.self, forKey: .lowColorHex)
        normalColorHex = try container.decodeIfPresent(String.self, forKey: .normalColorHex)
        highColorHex = try container.decodeIfPresent(String.self, forKey: .highColorHex)
    }

    public static let `default` = RamFillConfiguration(
        isVisible: true,
        lowThreshold: 50,
        highThreshold: 80,
        lowColorHex: "#34C759",
        normalColorHex: nil,
        highColorHex: "#FF3B30"
    )
}
