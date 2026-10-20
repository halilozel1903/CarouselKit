/// How a looping carousel lays out its pages.
///
/// A looping carousel repeats its `count` pages `copies` times in one scroll view and starts in the
/// middle copy, so there is always content on both sides. Each repeated page has a *slot*, its
/// position in the scroll view (`0..<slotCount`); `page(forSlot:)` maps it back to the page. When
/// scrolling gets close to either end, the carousel jumps without animation to the same page in the
/// middle copy (`recenteredSlot(for:)`), which looks the same.
///
/// A carousel that does not loop has one copy, and slots and pages are the same.
public struct LoopLayout: Sendable, Hashable {
    /// The number of pages.
    public let count: Int
    /// How many times the pages repeat. Always odd, so there is a middle copy.
    public let copies: Int
    /// How many copies from either end trigger a jump back to the middle.
    public let margin: Int

    /// The copies a looping layout uses unless told otherwise.
    public static let defaultCopies = 21

    /// A layout for `count` pages. `loops` repeats them `copies` times (rounded up to an odd number,
    /// at least 3); a single page never loops.
    public init(count: Int, loops: Bool, copies: Int = LoopLayout.defaultCopies) {
        self.count = max(0, count)
        if loops && count > 1 {
            let atLeastThree = max(3, copies)
            self.copies = atLeastThree.isMultiple(of: 2) ? atLeastThree + 1 : atLeastThree
        } else {
            self.copies = 1
        }
        // Jump back once scrolling enters the outer quarter of the copies.
        self.margin = self.copies == 1 ? 0 : max(1, self.copies / 4)
    }

    /// Whether the pages repeat.
    public var loops: Bool { copies > 1 }

    /// The number of slots in the scroll view.
    public var slotCount: Int { count * copies }

    /// The index of the middle copy.
    public var middleCopy: Int { copies / 2 }

    /// The page shown in `slot`.
    public func page(forSlot slot: Int) -> Int {
        CarouselIndex.wrapped(slot, count: count)
    }

    /// The copy `slot` belongs to.
    public func copy(ofSlot slot: Int) -> Int {
        guard count > 0 else { return 0 }
        return CarouselIndex.clamped(slot, count: slotCount) / count
    }

    /// The slot a carousel starts on to show `page`: in the middle copy when it loops.
    public func initialSlot(for page: Int) -> Int {
        guard count > 0 else { return 0 }
        return middleCopy * count + CarouselIndex.clamped(page, count: count)
    }

    /// The slot to scroll to to show `page`, starting from `slot`: the closest one, so a looping
    /// carousel takes the shorter way around (from the last page to the first goes forward one).
    public func slot(showing page: Int, from slot: Int) -> Int {
        guard count > 0 else { return 0 }
        let target = CarouselIndex.clamped(page, count: count)
        guard loops else { return target }
        let current = CarouselIndex.clamped(slot, count: slotCount)
        let offset = CarouselIndex.shortestOffset(from: self.page(forSlot: current), to: target, count: count)
        return CarouselIndex.clamped(current + offset, count: slotCount)
    }

    /// The slot after `slot` for auto scroll: the next slot when looping, the first page after the
    /// last one otherwise. A looping carousel recenters first (`recenteredSlot(for:)`), so it never
    /// runs out of slots.
    public func nextSlot(after slot: Int) -> Int {
        guard count > 0 else { return 0 }
        guard loops else {
            return CarouselIndex.nextAutoScrollIndex(after: CarouselIndex.clamped(slot, count: count), count: count)
        }
        return min(CarouselIndex.clamped(slot, count: slotCount) + 1, slotCount - 1)
    }

    /// The slot in the middle copy showing the same page as `slot`, when `slot` is within `margin`
    /// copies of either end; `nil` when it is far enough from both (or the layout does not loop).
    public func recenteredSlot(for slot: Int) -> Int? {
        guard loops, count > 0 else { return nil }
        let slotCopy = copy(ofSlot: slot)
        guard slotCopy < margin || slotCopy >= copies - margin else { return nil }
        return initialSlot(for: page(forSlot: slot))
    }
}
