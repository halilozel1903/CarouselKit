/// Which dots a dotted page indicator shows when there are more pages than fit.
///
/// Like the system page control, the indicator shows at most `maximumVisible` dots, keeps the
/// current one inside the window and shrinks the dots at an edge that has more pages behind it.
public struct DotWindow: Sendable, Hashable {
    /// The pages whose dots are shown.
    public let range: Range<Int>
    /// The number of pages.
    public let count: Int

    /// The window for `count` pages with `index` current, showing at most `maximumVisible` dots.
    public init(count: Int, index: Int, maximumVisible: Int) {
        let count = max(0, count)
        let visible = min(count, max(1, maximumVisible))
        self.count = count
        guard count > visible else {
            range = 0..<count
            return
        }
        let current = CarouselIndex.clamped(index, count: count)
        // Keep the current dot centered while possible.
        let start = CarouselIndex.clamped(current - visible / 2, count: count - visible + 1)
        range = start..<(start + visible)
    }

    /// The scale of the dot for `page`: 1 inside the window, smaller for the outermost dots when
    /// more pages lie beyond them.
    public func scale(of page: Int) -> Double {
        guard range.contains(page) else { return 0 }
        let first = range.lowerBound
        let last = range.upperBound - 1
        if page == first && first > 0 || page == last && last < count - 1 {
            return 0.5
        }
        if range.count > 4 && (page == first + 1 && first > 0 || page == last - 1 && last < count - 1) {
            return 0.75
        }
        return 1
    }
}
