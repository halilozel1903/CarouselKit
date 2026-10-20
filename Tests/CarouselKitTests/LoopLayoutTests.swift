import Testing
@testable import CarouselKit

@Suite("Loop mapping")
struct LoopLayoutTests {
    let layout = LoopLayout(count: 8, loops: true)

    @Test("A looping layout repeats the pages in an odd number of copies")
    func copies() {
        #expect(layout.loops)
        #expect(layout.copies == 21)
        #expect(layout.slotCount == 168)
        #expect(layout.middleCopy == 10)
        #expect(layout.margin == 5)
        #expect(LoopLayout(count: 8, loops: true, copies: 20).copies == 21)
        #expect(LoopLayout(count: 8, loops: true, copies: 1).copies == 3)
        #expect(LoopLayout(count: 8, loops: true, copies: 1).margin == 1)
    }

    @Test("One page or no loop means one copy")
    func singleCopy() {
        #expect(LoopLayout(count: 1, loops: true).copies == 1)
        #expect(!LoopLayout(count: 1, loops: true).loops)
        #expect(LoopLayout(count: 8, loops: false).slotCount == 8)
        #expect(LoopLayout(count: 0, loops: true).slotCount == 0)
    }

    @Test("Slots map back to their pages and copies")
    func pageForSlot() {
        #expect(layout.page(forSlot: 83) == 3)
        #expect(layout.page(forSlot: 167) == 7)
        #expect(layout.page(forSlot: 0) == 0)
        #expect(layout.copy(ofSlot: 39) == 4)
        #expect(layout.copy(ofSlot: 167) == 20)
    }

    @Test("A looping carousel starts in the middle copy")
    func initialSlot() {
        #expect(layout.initialSlot(for: 0) == 80)
        #expect(layout.initialSlot(for: 3) == 83)
        #expect(layout.initialSlot(for: 99) == 87)
        #expect(LoopLayout(count: 8, loops: false).initialSlot(for: 3) == 3)
    }

    @Test("Setting the index scrolls the shorter way around")
    func slotShowingPage() {
        // From the last page (slot 87) to the first goes forward one slot.
        #expect(layout.slot(showing: 0, from: 87) == 88)
        // From the first page (slot 80) to page 6 goes back two slots.
        #expect(layout.slot(showing: 6, from: 80) == 78)
        #expect(layout.slot(showing: 3, from: 83) == 83)
        let flat = LoopLayout(count: 8, loops: false)
        #expect(flat.slot(showing: 5, from: 2) == 5)
        #expect(flat.slot(showing: 12, from: 2) == 7)
    }

    @Test("Auto scroll moves one slot forward, or rewinds without a loop")
    func nextSlot() {
        #expect(layout.nextSlot(after: 80) == 81)
        #expect(layout.nextSlot(after: 167) == 167)
        let flat = LoopLayout(count: 4, loops: false)
        #expect(flat.nextSlot(after: 1) == 2)
        #expect(flat.nextSlot(after: 3) == 0)
    }

    @Test("Slots near either end recenter to the same page in the middle copy")
    func recentering() {
        #expect(layout.recenteredSlot(for: 83) == nil)
        #expect(layout.recenteredSlot(for: 127) == nil)
        #expect(layout.recenteredSlot(for: 39) == 87)
        #expect(layout.recenteredSlot(for: 128) == 80)
        #expect(layout.recenteredSlot(for: 0) == 80)
        #expect(LoopLayout(count: 8, loops: false).recenteredSlot(for: 0) == nil)
    }

    @Test("Recentering keeps the page")
    func recenteringKeepsPage() {
        for slot in 0..<layout.slotCount {
            if let target = layout.recenteredSlot(for: slot) {
                #expect(layout.page(forSlot: target) == layout.page(forSlot: slot))
                #expect(layout.copy(ofSlot: target) == layout.middleCopy)
            }
        }
    }
}
