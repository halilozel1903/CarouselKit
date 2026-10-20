import Foundation

/// How the pages of a carousel look as they move: `.plain`, `.scaled`, `.parallax` or `.stacked`.
///
/// A style turns a page's distance from the center, its *progress*, into a `CarouselTransform`.
/// Progress is 0 for the centered page, -1 for the page before it and 1 for the page after it, and
/// changes continuously while scrolling.
public struct CarouselStyle: Sendable, Hashable {
    enum Kind: Sendable, Hashable {
        case plain
        case scaled(minimumScale: Double, minimumOpacity: Double)
        case parallax(amount: Double)
        case stacked(visibleCards: Int, offset: Double, scaleStep: Double)
    }

    let kind: Kind

    /// Pages side by side, unchanged.
    public static let plain = CarouselStyle(kind: .plain)

    /// The centered page at full size, its neighbors smaller and dimmer.
    public static let scaled = CarouselStyle(kind: .scaled(minimumScale: 0.86, minimumOpacity: 0.65))

    /// The centered page at full size, its neighbors scaled to `minimumScale` and faded to
    /// `minimumOpacity`.
    public static func scaled(minimumScale: Double = 0.86, minimumOpacity: Double = 0.65) -> CarouselStyle {
        CarouselStyle(kind: .scaled(
            minimumScale: min(max(minimumScale, 0.1), 1),
            minimumOpacity: min(max(minimumOpacity, 0), 1)
        ))
    }

    /// Pages move at scroll speed while the layers marked with `.carouselParallax()` inside them
    /// move slower, which gives depth.
    public static let parallax = CarouselStyle(kind: .parallax(amount: 0.2))

    /// Parallax where marked layers lag behind by `amount` of their distance from the center
    /// (0.2 moves a layer a fifth less than its page).
    public static func parallax(amount: Double = 0.2) -> CarouselStyle {
        CarouselStyle(kind: .parallax(amount: min(max(amount, 0), 1)))
    }

    /// A deck: the next pages wait under the centered one, `offset` points apart and smaller each
    /// time, and slide out from under it when it moves away.
    public static let stacked = CarouselStyle(kind: .stacked(visibleCards: 2, offset: 22, scaleStep: 0.07))

    /// A deck showing `visibleCards` pages behind the centered one, each `offset` points further
    /// along and `scaleStep` smaller than the one in front.
    public static func stacked(visibleCards: Int = 2, offset: Double = 22, scaleStep: Double = 0.07) -> CarouselStyle {
        CarouselStyle(kind: .stacked(
            visibleCards: max(1, visibleCards),
            offset: max(0, offset),
            scaleStep: min(max(scaleStep, 0), 0.3)
        ))
    }

    /// The amount `.carouselParallax()` layers lag behind; 0 for every style but `.parallax`.
    public var parallaxAmount: Double {
        if case .parallax(let amount) = kind { return amount }
        return 0
    }

    /// Whether later pages draw under earlier ones (`.stacked`).
    public var stacksLaterPagesBelow: Bool {
        if case .stacked = kind { return true }
        return false
    }

    /// How a page `progress` pages from the center looks. `pageWidth` is the distance between
    /// neighboring pages (a page's width plus the spacing).
    public func transform(progress: Double, pageWidth: Double) -> CarouselTransform {
        switch kind {
        case .plain, .parallax:
            return .identity
        case let .scaled(minimumScale, minimumOpacity):
            let distance = min(abs(progress), 1)
            return CarouselTransform(
                scale: 1 - (1 - minimumScale) * distance,
                offsetX: 0,
                opacity: 1 - (1 - minimumOpacity) * distance
            )
        case let .stacked(visibleCards, offset, scaleStep):
            if progress <= 0 {
                // The centered page and the ones before it slide away normally, shrinking a little.
                let distance = min(-progress, 1)
                return CarouselTransform(
                    scale: 1 - scaleStep * distance,
                    offsetX: 0,
                    opacity: 1 - 0.35 * distance
                )
            }
            // Later pages are pulled back under the centered one, `offset` apart.
            let depth = min(progress, Double(visibleCards) + 1)
            let fade = max(0, depth - Double(visibleCards))
            return CarouselTransform(
                scale: 1 - scaleStep * depth,
                offsetX: -progress * pageWidth + offset * depth,
                opacity: max(0, 1 - fade)
            )
        }
    }
}

/// How one page of a carousel is drawn: scaled around its center, moved sideways and faded.
public struct CarouselTransform: Sendable, Hashable {
    /// The page's scale, 1 for full size.
    public var scale: Double
    /// Points the page moves along the scroll direction.
    public var offsetX: Double
    /// The page's opacity.
    public var opacity: Double

    public init(scale: Double = 1, offsetX: Double = 0, opacity: Double = 1) {
        self.scale = scale
        self.offsetX = offsetX
        self.opacity = opacity
    }

    /// No change.
    public static let identity = CarouselTransform()
}

/// Geometry shared by the carousel and its effects.
public enum CarouselGeometry {
    /// How many pages `itemMidX` is from the center of the viewport: 0 when centered, 1 when it is
    /// one page (`pageWidth`) to the right.
    public static func progress(itemMidX: Double, viewportMidX: Double, pageWidth: Double) -> Double {
        guard pageWidth > 0 else { return 0 }
        return (itemMidX - viewportMidX) / pageWidth
    }

    /// The offset of a parallax layer `distance` points from the viewport's center, for `amount`:
    /// it moves back toward the center by that share of the distance.
    public static func parallaxOffset(distance: Double, amount: Double) -> Double {
        -distance * amount
    }

    /// The scale a parallax layer of `width` needs to keep covering its frame while it moves up to
    /// `maximumOffset` points either way.
    public static func parallaxCoverScale(width: Double, maximumOffset: Double) -> Double {
        guard width > 0 else { return 1 }
        return 1 + 2 * abs(maximumOffset) / width
    }
}
