import Testing
@testable import CarouselKit

@Suite("Page indicators")
struct PageIndicatorTests {
    @Test("Few pages show every dot at full size")
    func fewPages() {
        let window = DotWindow(count: 5, index: 2, maximumVisible: 7)
        #expect(window.range == 0..<5)
        for page in 0..<5 {
            #expect(window.scale(of: page) == 1)
        }
    }

    @Test("Many pages show a window around the current page")
    func window() {
        let start = DotWindow(count: 20, index: 0, maximumVisible: 7)
        #expect(start.range == 0..<7)
        #expect(start.scale(of: 0) == 1)
        #expect(start.scale(of: 5) == 0.75)
        #expect(start.scale(of: 6) == 0.5)
        #expect(start.scale(of: 9) == 0)

        let middle = DotWindow(count: 20, index: 10, maximumVisible: 7)
        #expect(middle.range == 7..<14)
        #expect(middle.scale(of: 7) == 0.5)
        #expect(middle.scale(of: 10) == 1)

        let end = DotWindow(count: 20, index: 19, maximumVisible: 7)
        #expect(end.range == 13..<20)
        #expect(end.scale(of: 13) == 0.5)
        #expect(end.scale(of: 19) == 1)
    }

    @Test("The numbered style reads 3 / 8")
    func numbered() {
        #expect(PageIndicatorText.numbered(index: 2, count: 8) == "3 / 8")
        #expect(PageIndicatorText.numbered(index: 20, count: 8) == "8 / 8")
        #expect(PageIndicatorText.numbered(index: 0, count: 0) == "0 / 0")
        #expect(PageIndicatorText.accessibilityValue(index: 2, count: 8) == "Page 3 of 8")
    }

    @Test("The progress style fills up to the current page")
    func progress() {
        #expect(PageIndicatorText.filledFraction(index: 1, count: 4) == 0.5)
        #expect(PageIndicatorText.filledFraction(index: 3, count: 4) == 1)
        #expect(PageIndicatorText.filledFraction(index: 0, count: 0) == 0)
    }
}
