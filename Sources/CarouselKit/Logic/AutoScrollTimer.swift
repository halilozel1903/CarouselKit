import Foundation

/// The timing of auto scroll, kept apart from the view so it can be tested without a clock.
///
/// Times are seconds on any monotonic clock (the carousel uses `ProcessInfo.systemUptime`). The
/// timer advances every `interval` seconds. While someone drags, swipes or moves focus it is paused;
/// when they let go it waits `resumeDelay` seconds before the next page, so a page someone just
/// chose stays on screen.
public struct AutoScrollTimer: Sendable, Hashable {
    /// Seconds between pages.
    public var interval: TimeInterval
    /// Seconds to wait after an interaction ends before the next page.
    public var resumeDelay: TimeInterval
    /// Whether someone is interacting with the carousel right now.
    public private(set) var isInteracting = false
    /// Whether the timer is held, for example while the carousel is off screen.
    public private(set) var isSuspended = false
    /// When the current wait started.
    public private(set) var periodStart: TimeInterval
    /// When the next page is due, unless the timer is paused.
    public private(set) var deadline: TimeInterval

    /// A timer whose first page is due `interval` seconds after `now`.
    public init(interval: TimeInterval, resumeDelay: TimeInterval? = nil, now: TimeInterval) {
        self.interval = max(0.1, interval)
        self.resumeDelay = max(0, resumeDelay ?? self.interval)
        self.periodStart = now
        self.deadline = now + self.interval
    }

    /// Whether the timer is paused, by an interaction or a suspension.
    public var isPaused: Bool { isInteracting || isSuspended }

    /// When the next page is due, or `nil` while paused.
    public var nextFireTime: TimeInterval? {
        isPaused ? nil : deadline
    }

    /// Whether the next page is due at `now`.
    public func shouldAdvance(at now: TimeInterval) -> Bool {
        guard let nextFireTime else { return false }
        return now >= nextFireTime
    }

    /// How far the wait for the next page has come at `now`, from 0 to 1; 0 while paused.
    public func progress(at now: TimeInterval) -> Double {
        guard !isPaused else { return 0 }
        let length = deadline - periodStart
        guard length > 0 else { return 1 }
        return min(max((now - periodStart) / length, 0), 1)
    }

    /// Seconds from `now` until the next page is due; `nil` while paused, 0 when it is overdue.
    public func timeRemaining(at now: TimeInterval) -> TimeInterval? {
        nextFireTime.map { max(0, $0 - now) }
    }

    /// Records that the carousel showed the next page at `now`; the next one is due `interval`
    /// seconds later.
    public mutating func didAdvance(at now: TimeInterval) {
        restart(at: now, waiting: interval)
    }

    /// Records that someone started dragging, swiping or moving focus.
    public mutating func interactionBegan(at now: TimeInterval) {
        isInteracting = true
    }

    /// Records that the interaction ended at `now`; the next page is due `resumeDelay` seconds later.
    public mutating func interactionEnded(at now: TimeInterval) {
        isInteracting = false
        restart(at: now, waiting: resumeDelay)
    }

    /// Records a change of page that was not auto scroll's, when the start of the interaction was
    /// not observed (a tap on a page indicator, a focus move on Apple TV, a drag on iOS 17).
    public mutating func userChangedPage(at now: TimeInterval) {
        guard !isInteracting else { return }
        restart(at: now, waiting: resumeDelay)
    }

    /// Holds the timer, for example while the carousel is off screen.
    public mutating func suspend() {
        isSuspended = true
    }

    /// Releases a held timer; the next page is due a full `interval` after `now`.
    public mutating func resume(at now: TimeInterval) {
        guard isSuspended else { return }
        isSuspended = false
        restart(at: now, waiting: interval)
    }

    private mutating func restart(at now: TimeInterval, waiting seconds: TimeInterval) {
        periodStart = now
        deadline = now + seconds
    }
}
