import SwiftUI

/// A horizontal carousel that snaps one page at a time, with the neighbors peeking in at the sides.
///
/// ```swift
/// Carousel(destinations, index: $page, spacing: 16, peek: 28, style: .scaled) { destination in
///     DestinationCard(destination)
/// }
/// .frame(height: 420)
/// .carouselLoops()
/// .carouselAutoScroll(every: 5)
/// ```
///
/// Every page is as wide as the carousel minus `peek` and `spacing` on both sides
/// (`containerRelativeFrame`), and the scroll view snaps pages to the center
/// (`scrollTargetBehavior(.viewAligned)`). The carousel is as tall as its tallest page; give the
/// pages or the carousel a height.
///
/// - `index` binds the current page: it follows swipes, and setting it scrolls there (the shorter
///   way around in a looping carousel).
/// - `style` animates the pages by their distance from the center: `.plain`, `.scaled`,
///   `.parallax` or `.stacked`.
/// - `.carouselLoops()` repeats the pages endlessly; `.carouselAutoScroll(every:)` advances on a
///   timer that pauses while someone interacts.
/// - On Apple TV every page is focusable and moving focus pages the carousel; `onSelect` is called
///   when the focused page is clicked (on iOS when a page is tapped).
public struct Carousel<Item, Content: View>: View {
    private let items: [Item]
    private let index: Binding<Int>?
    private let spacing: CGFloat
    private let peek: CGFloat
    private let style: CarouselStyle
    private let onSelect: (@MainActor (Item) -> Void)?
    private let content: (Item) -> Content

    @Environment(\.carouselLoops) private var loops
    @Environment(\.carouselAutoScroll) private var autoScroll
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The slot in the center (see `LoopLayout`).
    @State private var slot: Int?
    /// The slot the carousel itself scrolled to, so the change is not taken for an interaction.
    @State private var expectedSlot: Int?
    /// The page shown last, kept to restore it when the layout changes.
    @State private var lastPage = 0
    @State private var timer: AutoScrollTimer?
    #if os(tvOS)
    @FocusState private var focusedSlot: Int?
    #endif

    /// A carousel of `data`, one page per element.
    ///
    /// - Parameters:
    ///   - data: The pages' items.
    ///   - index: The current page, if you want to read or set it.
    ///   - spacing: Points between pages.
    ///   - peek: How many points of the previous and next page show at the sides.
    ///   - style: How pages look as they move.
    ///   - onSelect: Called with the page's item when it is tapped (iOS) or clicked (Apple TV).
    ///   - content: The view for one page.
    public init<Data: RandomAccessCollection>(
        _ data: Data,
        index: Binding<Int>? = nil,
        spacing: CGFloat = CarouselDefaults.spacing,
        peek: CGFloat = CarouselDefaults.peek,
        style: CarouselStyle = .plain,
        onSelect: (@MainActor (Item) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) where Data.Element == Item {
        self.items = Array(data)
        self.index = index
        self.spacing = max(0, spacing)
        self.peek = max(0, peek)
        self.style = style
        self.onSelect = onSelect
        self.content = content
    }

    private var layout: LoopLayout {
        LoopLayout(count: items.count, loops: loops)
    }

    /// Auto scroll, unless Reduce Motion is on or there is nothing to scroll to.
    private var activeAutoScroll: CarouselAutoScroll? {
        guard !reduceMotion, items.count > 1 else { return nil }
        return autoScroll
    }

    public var body: some View {
        let layout = self.layout
        ScrollView(.horizontal) {
            LazyHStack(spacing: spacing) {
                ForEach(0..<layout.slotCount, id: \.self) { slot in
                    page(at: slot, in: layout)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .scrollPosition(id: $slot, anchor: .center)
        // The pages fill the width minus this padding (containerRelativeFrame), and snap to it.
        .safeAreaPadding(.horizontal, peek + spacing)
        #if os(tvOS)
        // Focused pages grow; let them draw outside the scroll view.
        .scrollClipDisabled()
        .focusSection()
        .defaultFocus($focusedSlot, slot ?? layout.initialSlot(for: lastPage))
        .onChange(of: focusedSlot) { _, newValue in
            focusMoved(to: newValue)
        }
        #endif
        .environment(\.carouselParallaxAmount, style.parallaxAmount)
        .modifier(ScrollInteractionObserver(
            began: { timer?.interactionBegan(at: carouselNow()) },
            ended: { timer?.interactionEnded(at: carouselNow()) }
        ))
        .onAppear {
            guard slot == nil else { return }
            show(slot: layout.initialSlot(for: index?.wrappedValue ?? lastPage), animated: false)
        }
        .onChange(of: layout) { _, newLayout in
            show(slot: newLayout.initialSlot(for: lastPage), animated: false)
        }
        .onChange(of: slot) { _, newValue in
            slotChanged(to: newValue)
        }
        .onChange(of: index?.wrappedValue) { _, newValue in
            if let newValue { indexChanged(to: newValue) }
        }
        .task(id: slot) {
            await recenterWhenIdle()
        }
        .task(id: AutoScrollKey(settings: activeAutoScroll, count: items.count, loops: loops)) {
            await runAutoScroll()
        }
    }

    // MARK: - Pages

    @ViewBuilder
    private func page(at slot: Int, in layout: LoopLayout) -> some View {
        let item = items[layout.page(forSlot: slot)]
        let style = self.style
        let spacing = Double(self.spacing)
        pageContent(item, slot: slot)
            .containerRelativeFrame(.horizontal)
            .visualEffect { effect, proxy in
                // The scroll view's visible bounds in this page's coordinates.
                let viewport = proxy.bounds(of: .scrollView(axis: .horizontal))
                let pageWidth = Double(proxy.size.width) + spacing
                let progress = viewport.map {
                    CarouselGeometry.progress(
                        itemMidX: Double(proxy.size.width) / 2,
                        viewportMidX: Double($0.midX),
                        pageWidth: pageWidth
                    )
                } ?? 0
                let transform = style.transform(progress: progress, pageWidth: pageWidth)
                return effect
                    .scaleEffect(transform.scale)
                    .offset(x: transform.offsetX)
                    .opacity(transform.opacity)
            }
            .zIndex(style.stacksLaterPagesBelow ? -Double(slot) : 0)
            .accessibilityAddTraits(slot == self.slot ? .isSelected : [])
            .id(slot)
    }

    @ViewBuilder
    private func pageContent(_ item: Item, slot: Int) -> some View {
        #if os(tvOS)
        Button {
            onSelect?(item)
        } label: {
            content(item)
        }
        .buttonStyle(CarouselPageButtonStyle())
        .focused($focusedSlot, equals: slot)
        #else
        if let onSelect {
            Button {
                onSelect(item)
            } label: {
                content(item)
            }
            .buttonStyle(CarouselPageButtonStyle())
        } else {
            content(item)
        }
        #endif
    }

    // MARK: - Position

    /// Scrolls to `slot` as the carousel's own move (not an interaction).
    private func show(slot newSlot: Int, animated: Bool) {
        guard newSlot != slot else { return }
        expectedSlot = newSlot
        if animated {
            withAnimation(.smooth(duration: 0.55)) { slot = newSlot }
        } else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { slot = newSlot }
        }
        #if os(tvOS)
        if focusedSlot != nil, focusedSlot != newSlot {
            focusedSlot = newSlot
        }
        #endif
    }

    private func slotChanged(to newValue: Int?) {
        guard let newValue else { return }
        let page = layout.page(forSlot: newValue)
        lastPage = page
        if let index, index.wrappedValue != page {
            index.wrappedValue = page
        }
        if newValue == expectedSlot {
            expectedSlot = nil
        } else {
            // A swipe the scroll phase did not report (iOS 17), or a page reached by focus.
            timer?.userChangedPage(at: carouselNow())
        }
        #if os(tvOS)
        if focusedSlot != nil, focusedSlot != newValue {
            focusedSlot = newValue
        }
        #endif
    }

    private func indexChanged(to newPage: Int) {
        let layout = self.layout
        guard layout.count > 0 else { return }
        let target = CarouselIndex.clamped(newPage, count: layout.count)
        guard let current = slot, layout.page(forSlot: current) != target else { return }
        timer?.userChangedPage(at: carouselNow())
        show(slot: layout.slot(showing: target, from: current), animated: true)
    }

    #if os(tvOS)
    private func focusMoved(to newValue: Int?) {
        guard let newValue, newValue != slot else { return }
        timer?.userChangedPage(at: carouselNow())
        expectedSlot = newValue
        withAnimation(.smooth(duration: 0.45)) { slot = newValue }
    }
    #endif

    /// A looping carousel close to either end jumps to the same page in the middle copy once it
    /// has come to rest.
    private func recenterWhenIdle() async {
        guard let current = slot, let target = layout.recenteredSlot(for: current) else { return }
        try? await Task.sleep(for: .seconds(1))
        guard !Task.isCancelled, slot == current, timer?.isInteracting != true else { return }
        show(slot: target, animated: false)
    }

    // MARK: - Auto scroll

    private func runAutoScroll() async {
        guard let settings = activeAutoScroll else {
            timer = nil
            return
        }
        timer = AutoScrollTimer(interval: settings.interval, resumeDelay: settings.resumeDelay, now: carouselNow())
        while !Task.isCancelled {
            let wait = timer?.timeRemaining(at: carouselNow()) ?? 0.25
            try? await Task.sleep(for: .seconds(min(max(wait, 0.05), 0.5)))
            guard !Task.isCancelled else { break }
            if timer?.shouldAdvance(at: carouselNow()) == true {
                advance()
            }
        }
    }

    private func advance() {
        let layout = self.layout
        guard let current = slot, layout.count > 1 else { return }
        if let recentered = layout.recenteredSlot(for: current) {
            // Move to the middle copy first; the next tick scrolls on from there.
            show(slot: recentered, animated: false)
            return
        }
        show(slot: layout.nextSlot(after: current), animated: true)
        timer?.didAdvance(at: carouselNow())
    }
}

/// The default spacing and peek of carousels on this platform.
public enum CarouselDefaults {
    #if os(tvOS)
    public static let spacing: CGFloat = 48
    public static let peek: CGFloat = 160
    #else
    public static let spacing: CGFloat = 16
    public static let peek: CGFloat = 28
    #endif
}

/// What restarts the auto scroll task when it changes.
private struct AutoScrollKey: Hashable {
    let settings: CarouselAutoScroll?
    let count: Int
    let loops: Bool
}

/// A monotonic clock in seconds for the auto scroll timer.
func carouselNow() -> TimeInterval {
    ProcessInfo.processInfo.systemUptime
}

/// Reports drags and swipes through the scroll phase where the system has it (iOS 18, tvOS 18).
/// On earlier versions a page change that the carousel did not make counts as an interaction.
private struct ScrollInteractionObserver: ViewModifier {
    let began: @MainActor () -> Void
    let ended: @MainActor () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, tvOS 18.0, macOS 15.0, *) {
            content.onScrollPhaseChange { oldPhase, newPhase in
                switch newPhase {
                case .tracking, .interacting:
                    began()
                case .idle where oldPhase != .animating:
                    ended()
                default:
                    break
                }
            }
        } else {
            content
        }
    }
}

/// The button style of carousel pages: on Apple TV the focused page lifts and casts a shadow, on
/// iOS a pressed page dips slightly.
struct CarouselPageButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        CarouselPageButtonBody(configuration: configuration)
    }
}

private struct CarouselPageButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .scaleEffect(scale)
            .shadow(color: .black.opacity(isFocused ? 0.45 : 0), radius: isFocused ? 30 : 0, y: isFocused ? 18 : 0)
            .animation(reduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.32, dampingFraction: 0.75), value: isFocused)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(Rectangle())
    }

    private var scale: CGFloat {
        if reduceMotion { return 1 }
        if configuration.isPressed { return isFocused ? 1.02 : 0.98 }
        return isFocused ? 1.05 : 1
    }
}
