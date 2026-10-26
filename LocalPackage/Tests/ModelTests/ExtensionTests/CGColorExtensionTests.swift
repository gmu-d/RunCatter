import CoreGraphics
import Foundation
import Testing

@testable import Model

struct CGColorExtensionTests {
    @Test
    func from_hex_creates_srgb_color_components() throws {
        let color = try #require(CGColor.from(hex: "#FF3B30"))
        let components = try #require(color.components)
        let expected: [CGFloat] = [1.0, 59.0 / 255.0, 48.0 / 255.0, 1.0]
        #expect(components.count == expected.count)
        #expect(zip(components, expected).allSatisfy { abs($0 - $1) < 0.0001 })
    }

    @Test
    func from_hex_accepts_value_without_hash_prefix() throws {
        #expect(try #require(CGColor.from(hex: "00FF00")).components == [0.0, 1.0, 0.0, 1.0])
    }

    @Test
    func from_hex_returns_nil_for_invalid_input() {
        #expect(CGColor.from(hex: "#12345") == nil)
        #expect(CGColor.from(hex: "#GGHHII") == nil)
        #expect(CGColor.from(hex: "") == nil)
    }
}
