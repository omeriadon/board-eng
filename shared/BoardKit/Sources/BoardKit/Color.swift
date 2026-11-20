/// A plain linear-ish sRGB colour in 0...1. Cheap to copy, interpolate and encode.
public struct RGB: Hashable, Sendable {
	public var r: Float
	public var g: Float
	public var b: Float

	public init(_ r: Float, _ g: Float, _ b: Float) {
		self.r = r
		self.g = g
		self.b = b
	}

	public init(hex: UInt32) {
		self.init(Float((hex >> 16) & 0xFF) / 255, Float((hex >> 8) & 0xFF) / 255, Float(hex & 0xFF) / 255)
	}

	public static let black = RGB(0, 0, 0)
	public static let white = RGB(1, 1, 1)

	public var hex: UInt32 {
		let p = pixel
		return UInt32(p.r) << 16 | UInt32(p.g) << 8 | UInt32(p.b)
	}

	public func mixed(_ other: RGB, _ t: Float) -> RGB {
		RGB(r + (other.r - r) * t, g + (other.g - g) * t, b + (other.b - b) * t)
	}

	public var clamped: RGB { RGB(limit(r, 0, 0, 1), limit(g, 0, 0, 1), limit(b, 0, 0, 1)) }

	public func scaled(_ k: Float) -> RGB { RGB(r * k, g * k, b * k) }

	/// Perceived brightness, 0...1.
	public var luminance: Float { 0.2126 * r + 0.7152 * g + 0.0722 * b }

	public var pixel: Pixel {
		@inline(__always) func byte(_ v: Float) -> UInt8 { UInt8(clamp(v * 255 + 0.5, 0, 255)) }
		return Pixel(r: byte(r), g: byte(g), b: byte(b))
	}
}

/// One LED's 8-bit colour, exactly as sent to a WS2812.
public struct Pixel: Hashable, Sendable {
	public var r: UInt8
	public var g: UInt8
	public var b: UInt8

	public init(r: UInt8, g: UInt8, b: UInt8) {
		self.r = r
		self.g = g
		self.b = b
	}

	public static let off = Pixel(r: 0, g: 0, b: 0)

	public var rgb: RGB { RGB(Float(r) / 255, Float(g) / 255, Float(b) / 255) }
}

@inline(__always) func clamp(_ v: Float, _ lo: Float, _ hi: Float) -> Float { v < lo ? lo : (v > hi ? hi : v) }
@inline(__always) func fract(_ v: Float) -> Float { v - v.rounded(.down) }
@inline(__always) func smoothstep(_ e0: Float, _ e1: Float, _ x: Float) -> Float {
	let t = clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
}

#if !hasFeature(Embedded)
	extension RGB: Codable {}
	extension Pixel: Codable {}
#endif
