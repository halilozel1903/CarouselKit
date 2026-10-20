import SwiftUI

/// Auto scroll settings, set with `.carouselAutoScroll(every:resumeAfter:)`.
public struct CarouselAutoScroll: Sendable, Hashable {
    /// Seconds between pages.
    public var interval: TimeInterval
    /// Seconds to wait after someone drags, swipes or moves focus before scrolling again.
    public var resumeDelay: TimeInterval

    public init(interval: TimeInterval = 4, resumeDelay: TimeInterval? = nil) {
        self.interval = max(0.5, interval)
        self.resumeDelay = max(0, resumeDelay ?? self.interval)
    }
}

extension EnvironmentValues {
    /// Whether carousels repeat their pages endlessly.
    @Entry var carouselLoops: Bool = false
    /// The auto scroll of carousels, `nil` when they do not scroll on their own.
    @Entry var carouselAutoScroll: CarouselAutoScroll? = nil
    /// How far `.carouselParallax()` layers lag behind, set by the `.parallax` style.
    @Entry var carouselParallaxAmount: Double = 0
}

extension View {
    /// Makes the carousels in this view loop: after the last page comes the first one again, in both
    /// directions, with no visible jump.
    public func carouselLoops(_ loops: Bool = true) -> some View {
        environment(\.carouselLoops, loops)
    }

    /// Makes the carousels in this view advance a page every `interval` seconds. Dragging, swiping,
    /// moving focus or changing the bound index pauses auto scroll; it resumes `resumeAfter`
    /// seconds after the interaction (by default one interval). Auto scroll stops while Reduce
    /// Motion is on and while the carousel is off screen. A carousel that does not loop rewinds to
    /// the first page after the last.
    public func carouselAutoScroll(
        every interval: TimeInterval = 4,
        resumeAfter resumeDelay: TimeInterval? = nil,
        isEnabled: Bool = true
    ) -> some View {
        environment(\.carouselAutoScroll, isEnabled ? CarouselAutoScroll(interval: interval, resumeDelay: resumeDelay) : nil)
    }

    /// Marks a layer of a carousel page, typically its background art, to move slower than the
    /// page in a `.parallax` carousel. The layer is scaled up just enough to keep covering its frame
    /// and clipped to it. `factor` scales the style's amount (use 2 for a layer twice as deep, a
    /// negative value to move the other way). Outside a `.parallax` carousel nothing changes.
    public func carouselParallax(_ factor: Double = 1) -> some View {
        modifier(CarouselParallaxModifier(factor: factor))
    }
}

struct CarouselParallaxModifier: ViewModifier {
    let factor: Double
    @Environment(\.carouselParallaxAmount) private var styleAmount

    func body(content: Content) -> some View {
        let amount = styleAmount * factor
        if amount == 0 {
            content
        } else {
            content
                .visualEffect { effect, proxy in
                    let frame = proxy.frame(in: .scrollView(axis: .horizontal))
                    let viewport = proxy.bounds(of: .scrollView(axis: .horizontal)) ?? frame
                    // A layer only needs to keep covering its frame while its page is on screen,
                    // up to about one page from the center.
                    let reach = min(viewport.width, frame.width * 1.15)
                    let distance = min(max(frame.midX - viewport.midX, -reach), reach)
                    let scale = CarouselGeometry.parallaxCoverScale(width: frame.width, maximumOffset: reach * amount)
                    let offset = CarouselGeometry.parallaxOffset(distance: distance, amount: amount)
                    return effect
                        .scaleEffect(scale)
                        .offset(x: offset)
                }
                .clipped()
        }
    }
}
