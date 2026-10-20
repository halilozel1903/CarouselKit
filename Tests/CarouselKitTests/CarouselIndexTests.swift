import Testing
@testable import CarouselKit

@Suite("Index wrapping")
struct CarouselIndexTests {
    @Test("Wrapping handles negative and large indices")
    func wrapping() {
        #expect(CarouselIndex.wrapped(-1, count: 5) == 4)
        #expect(CarouselIndex.wrapped(7, count: 5) == 2)
        #expect(CarouselIndex.wrapped(-6, count: 5) == 4)
        #expect(CarouselIndex.wrapped(10, count: 5) == 0)
        #expect(CarouselIndex.wrapped(3, count: 0) == 0)
    }

    @Test("Clamping keeps the index inside the pages")
    func clamping() {
        #expect(CarouselIndex.clamped(-3, count: 4) == 0)
        #expect(CarouselIndex.clamped(9, count: 4) == 3)
        #expect(CarouselIndex.clamped(2, count: 4) == 2)
        #expect(CarouselIndex.clamped(2, count: 0) == 0)
    }

    @Test("Stepping wraps when looping and stops at the ends otherwise")
    func stepping() {
        #expect(CarouselIndex.step(from: 3, by: 1, count: 4, loops: false) == nil)
        #expect(CarouselIndex.step(from: 3, by: 1, count: 4, loops: true) == 0)
        #expect(CarouselIndex.step(from: 0, by: -1, count: 4, loops: true) == 3)
        #expect(CarouselIndex.step(from: 0, by: -1, count: 4, loops: false) == nil)
        #expect(CarouselIndex.step(from: 1, by: 1, count: 4, loops: false) == 2)
        #expect(CarouselIndex.step(from: 0, by: 1, count: 0, loops: true) == nil)
    }

    @Test("Auto scroll goes to the next page and rewinds after the last")
    func autoScrollIndex() {
        #expect(CarouselIndex.nextAutoScrollIndex(after: 2, count: 8) == 3)
        #expect(CarouselIndex.nextAutoScrollIndex(after: 7, count: 8) == 0)
        #expect(CarouselIndex.nextAutoScrollIndex(after: 0, count: 0) == 0)
    }

    @Test("The shortest offset takes the shorter way around")
    func shortestOffset() {
        #expect(CarouselIndex.shortestOffset(from: 7, to: 0, count: 8) == 1)
        #expect(CarouselIndex.shortestOffset(from: 0, to: 7, count: 8) == -1)
        #expect(CarouselIndex.shortestOffset(from: 0, to: 3, count: 5) == -2)
        #expect(CarouselIndex.shortestOffset(from: 1, to: 1, count: 5) == 0)
        // A tie goes forward.
        #expect(CarouselIndex.shortestOffset(from: 0, to: 2, count: 4) == 2)
    }
}
