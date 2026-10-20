/// Index arithmetic for carousels: wrapping, clamping and stepping through `count` pages.
///
/// Every function is pure and works for any `count`; an empty carousel (`count <= 0`) has no valid
/// index, and the functions return `0` or `nil` for it.
public enum CarouselIndex {
    /// `index` wrapped into `0..<count`, also for negative indices: `wrapped(-1, count: 5) == 4`,
    /// `wrapped(7, count: 5) == 2`.
    public static func wrapped(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let remainder = index % count
        return remainder >= 0 ? remainder : remainder + count
    }

    /// `index` clamped into `0..<count`.
    public static func clamped(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return min(max(index, 0), count - 1)
    }

    /// The page `offset` pages away from `index`. A looping carousel wraps around; one that does not
    /// loop returns `nil` past either end.
    public static func step(from index: Int, by offset: Int, count: Int, loops: Bool) -> Int? {
        guard count > 0 else { return nil }
        let target = index + offset
        if loops {
            return wrapped(target, count: count)
        }
        return (0..<count).contains(target) ? target : nil
    }

    /// The page auto scroll shows after `index`: the next one, and the first one again after the
    /// last (a looping carousel keeps going forward, one that does not loop rewinds).
    public static func nextAutoScrollIndex(after index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return wrapped(index + 1, count: count)
    }

    /// The signed number of pages from `index` to `target` along the shorter way around a loop of
    /// `count` pages. Ties go forward: `shortestOffset(from: 0, to: 2, count: 4) == 2`.
    public static func shortestOffset(from index: Int, to target: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let forward = wrapped(target - index, count: count)
        let backward = forward - count
        return forward <= -backward ? forward : backward
    }
}
