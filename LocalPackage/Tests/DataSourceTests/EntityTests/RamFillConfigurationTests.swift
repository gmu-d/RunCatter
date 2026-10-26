import Foundation
import Testing

@testable import DataSource

struct RamFillConfigurationTests {
    @Test
    func default_configuration_uses_fifty_eighty_thresholds_with_green_and_red() {
        #expect(RamFillConfiguration.default == RamFillConfiguration(
            lowThreshold: 50,
            highThreshold: 80,
            lowColorHex: "#34C759",
            normalColorHex: nil,
            highColorHex: "#FF3B30"
        ))
    }

    @Test
    func decode_matches_encoded_configuration() throws {
        let configuration = RamFillConfiguration(
            lowThreshold: 40,
            highThreshold: 90,
            lowColorHex: nil,
            normalColorHex: "#00FF00",
            highColorHex: nil
        )
        let data = try JSONEncoder().encode(configuration)
        #expect(try JSONDecoder().decode(RamFillConfiguration.self, from: data) == configuration)
    }

    @Test
    func decode_without_isVisible_defaults_to_visible() throws {
        let data = Data(####"{"lowThreshold":50,"highThreshold":80,"lowColorHex":"#34C759","highColorHex":"#FF3B30"}"####.utf8)
        #expect(try JSONDecoder().decode(RamFillConfiguration.self, from: data).isVisible == true)
    }
}
