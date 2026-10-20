import Testing
@testable import CarouselKit

@Suite("Auto scroll timing")
struct AutoScrollTimerTests {
    @Test("The first page is due one interval after the start")
    func firstDeadline() {
        let timer = AutoScrollTimer(interval: 4, now: 100)
        #expect(timer.nextFireTime == 104)
        #expect(!timer.shouldAdvance(at: 103.9))
        #expect(timer.shouldAdvance(at: 104))
        #expect(timer.progress(at: 102) == 0.5)
        #expect(timer.timeRemaining(at: 101) == 3)
        #expect(timer.timeRemaining(at: 105) == 0)
        #expect(timer.resumeDelay == 4)
    }

    @Test("Advancing restarts the interval")
    func advancing() {
        var timer = AutoScrollTimer(interval: 4, now: 100)
        timer.didAdvance(at: 104)
        #expect(timer.nextFireTime == 108)
        #expect(timer.progress(at: 104) == 0)
        #expect(timer.progress(at: 110) == 1)
    }

    @Test("An interaction pauses the timer")
    func interactionPauses() {
        var timer = AutoScrollTimer(interval: 4, resumeDelay: 6, now: 100)
        timer.interactionBegan(at: 101)
        #expect(timer.isPaused)
        #expect(timer.nextFireTime == nil)
        #expect(!timer.shouldAdvance(at: 200))
        #expect(timer.progress(at: 200) == 0)
        #expect(timer.timeRemaining(at: 200) == nil)
    }

    @Test("Auto scroll resumes after the resume delay")
    func resumes() {
        var timer = AutoScrollTimer(interval: 4, resumeDelay: 6, now: 100)
        timer.interactionBegan(at: 101)
        timer.interactionEnded(at: 110)
        #expect(!timer.isPaused)
        #expect(timer.nextFireTime == 116)
        #expect(!timer.shouldAdvance(at: 115))
        #expect(timer.shouldAdvance(at: 116))
    }

    @Test("A page change from outside restarts the wait, except during an interaction")
    func userChangedPage() {
        var timer = AutoScrollTimer(interval: 4, resumeDelay: 6, now: 100)
        timer.userChangedPage(at: 105)
        #expect(timer.nextFireTime == 111)
        timer.interactionBegan(at: 106)
        timer.userChangedPage(at: 107)
        #expect(timer.nextFireTime == nil)
        timer.interactionEnded(at: 108)
        #expect(timer.nextFireTime == 114)
    }

    @Test("A suspended timer waits a full interval after resuming")
    func suspension() {
        var timer = AutoScrollTimer(interval: 4, now: 0)
        timer.suspend()
        #expect(timer.nextFireTime == nil)
        timer.resume(at: 50)
        #expect(timer.nextFireTime == 54)
        // Resuming a running timer changes nothing.
        timer.resume(at: 52)
        #expect(timer.nextFireTime == 54)
    }

    @Test("Intervals and delays are kept positive")
    func clamping() {
        let timer = AutoScrollTimer(interval: 0, resumeDelay: -3, now: 0)
        #expect(timer.interval == 0.1)
        #expect(timer.resumeDelay == 0)
        let settings = CarouselAutoScroll(interval: 0.1)
        #expect(settings.interval == 0.5)
        #expect(settings.resumeDelay == 0.5)
        #expect(CarouselAutoScroll(interval: 5, resumeDelay: 2).resumeDelay == 2)
    }
}
