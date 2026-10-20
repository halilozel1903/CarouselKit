import Testing
@testable import CarouselKit

@Suite("Carousel styles")
struct StyleTests {
    @Test("Plain and parallax pages are not transformed")
    func plain() {
        #expect(CarouselStyle.plain.transform(progress: 0.7, pageWidth: 300) == .identity)
        #expect(CarouselStyle.parallax.transform(progress: -1, pageWidth: 300) == .identity)
        #expect(CarouselStyle.parallax.parallaxAmount == 0.2)
        #expect(CarouselStyle.parallax(amount: 3).parallaxAmount == 1)
        #expect(CarouselStyle.plain.parallaxAmount == 0)
        #expect(CarouselStyle.scaled.parallaxAmount == 0)
    }

    @Test("Scaled pages shrink and fade with their distance, up to one page")
    func scaled() {
        let style = CarouselStyle.scaled(minimumScale: 0.8, minimumOpacity: 0.5)
        let center = style.transform(progress: 0, pageWidth: 300)
        #expect(center == .identity)
        let neighbor = style.transform(progress: 1, pageWidth: 300)
        #expect(isClose(neighbor.scale, 0.8))
        #expect(isClose(neighbor.opacity, 0.5))
        #expect(style.transform(progress: -3, pageWidth: 300) == neighbor)
        let halfway = style.transform(progress: -0.5, pageWidth: 300)
        #expect(isClose(halfway.scale, 0.9))
        #expect(isClose(halfway.opacity, 0.75))
        #expect(halfway.offsetX == 0)
    }

    @Test("Scaled parameters are clamped")
    func scaledClamping() {
        let style = CarouselStyle.scaled(minimumScale: 2, minimumOpacity: -1)
        let neighbor = style.transform(progress: 1, pageWidth: 300)
        #expect(neighbor.scale == 1)
        #expect(neighbor.opacity == 0)
    }

    @Test("Stacked pages wait under the centered one")
    func stacked() {
        let style = CarouselStyle.stacked(visibleCards: 2, offset: 20, scaleStep: 0.1)
        #expect(style.stacksLaterPagesBelow)
        #expect(!CarouselStyle.scaled.stacksLaterPagesBelow)

        let next = style.transform(progress: 1, pageWidth: 300)
        #expect(isClose(next.scale, 0.9))
        #expect(isClose(next.offsetX, -280))
        #expect(next.opacity == 1)

        let hidden = style.transform(progress: 3, pageWidth: 300)
        #expect(isClose(hidden.scale, 0.7))
        #expect(isClose(hidden.offsetX, -840))
        #expect(hidden.opacity == 0)

        let previous = style.transform(progress: -1, pageWidth: 300)
        #expect(isClose(previous.scale, 0.9))
        #expect(previous.offsetX == 0)
        #expect(isClose(previous.opacity, 0.65))
    }

    @Test("A stacked page sits offset points per depth from the center")
    func stackedPosition() {
        let style = CarouselStyle.stacked(visibleCards: 2, offset: 20, scaleStep: 0.1)
        for progress in [0.25, 0.5, 1.0, 1.5, 2.0] as [Double] {
            let transform = style.transform(progress: progress, pageWidth: 300)
            // Its layout position plus its offset.
            #expect(isClose(progress * 300 + transform.offsetX, 20 * progress))
        }
    }

    @Test("Progress is the distance from the center in pages")
    func geometry() {
        #expect(CarouselGeometry.progress(itemMidX: 350, viewportMidX: 200, pageWidth: 300) == 0.5)
        #expect(CarouselGeometry.progress(itemMidX: -100, viewportMidX: 200, pageWidth: 300) == -1)
        #expect(CarouselGeometry.progress(itemMidX: 350, viewportMidX: 200, pageWidth: 0) == 0)
        #expect(isClose(CarouselGeometry.parallaxOffset(distance: 100, amount: 0.2), -20))
        #expect(CarouselGeometry.parallaxCoverScale(width: 200, maximumOffset: 50) == 1.5)
        #expect(CarouselGeometry.parallaxCoverScale(width: 0, maximumOffset: 50) == 1)
    }
}
