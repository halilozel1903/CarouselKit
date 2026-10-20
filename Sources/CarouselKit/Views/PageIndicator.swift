import SwiftUI

/// How a `PageIndicator` shows the current page.
public struct PageIndicatorStyle: Sendable, Hashable {
    enum Kind: Sendable, Hashable {
        case dots(maximumVisible: Int)
        case line
        case numbered
        case progress
    }

    let kind: Kind

    /// A dot per page, the current one stretched into a capsule. With more than `maximumVisible`
    /// pages the dots scroll and shrink at the edges, like the system page control.
    public static let dots = PageIndicatorStyle(kind: .dots(maximumVisible: 7))

    /// Dots, at most `maximumVisible` at a time.
    public static func dots(maximumVisible: Int = 7) -> PageIndicatorStyle {
        PageIndicatorStyle(kind: .dots(maximumVisible: max(3, maximumVisible)))
    }

    /// A track with a thumb one page long that slides to the current page.
    public static let line = PageIndicatorStyle(kind: .line)

    /// The page number and the count, "3 / 8", in a capsule.
    public static let numbered = PageIndicatorStyle(kind: .numbered)

    /// A segment per page, filled up to the current one, like story progress bars.
    public static let progress = PageIndicatorStyle(kind: .progress)
}

/// Formatting shared by the page indicators.
public enum PageIndicatorText {
    /// "3 / 8" for the third of eight pages (`index` is zero-based); "0 / 0" without pages.
    public static func numbered(index: Int, count: Int) -> String {
        guard count > 0 else { return "0 / 0" }
        return "\(CarouselIndex.clamped(index, count: count) + 1) / \(count)"
    }

    /// The VoiceOver value: "Page 3 of 8".
    public static func accessibilityValue(index: Int, count: Int) -> String {
        guard count > 0 else { return "No pages" }
        return "Page \(CarouselIndex.clamped(index, count: count) + 1) of \(count)"
    }

    /// How much of the `progress` style is filled: the share of pages up to and including the
    /// current one.
    public static func filledFraction(index: Int, count: Int) -> Double {
        guard count > 0 else { return 0 }
        return Double(CarouselIndex.clamped(index, count: count) + 1) / Double(count)
    }
}

/// Shows which page of a carousel is current, as dots, a line, "3 / 8" or progress segments.
///
/// ```swift
/// Carousel(items, index: $page) { item in Card(item) }
/// PageIndicator(count: items.count, index: $page, style: .dots)
///     .tint(.white)
/// ```
///
/// The current page is drawn in the tint color, the others in the tint at lower opacity. With a
/// binding, tapping a dot or segment (iOS) and VoiceOver's adjustable action change the page.
public struct PageIndicator: View {
    private let count: Int
    private let index: Int
    private let setIndex: ((Int) -> Void)?
    private let style: PageIndicatorStyle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// An indicator that can change the page.
    public init(count: Int, index: Binding<Int>, style: PageIndicatorStyle = .dots) {
        self.count = max(0, count)
        self.index = index.wrappedValue
        self.setIndex = { index.wrappedValue = $0 }
        self.style = style
    }

    /// An indicator that only shows the page.
    public init(count: Int, index: Int, style: PageIndicatorStyle = .dots) {
        self.count = max(0, count)
        self.index = index
        self.setIndex = nil
        self.style = style
    }

    private var current: Int { CarouselIndex.clamped(index, count: count) }

    public var body: some View {
        Group {
            switch style.kind {
            case .dots(let maximumVisible):
                dots(maximumVisible: maximumVisible)
            case .line:
                line
            case .numbered:
                numbered
            case .progress:
                progress
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page")
        .accessibilityValue(PageIndicatorText.accessibilityValue(index: current, count: count))
        .accessibilityAdjustableAction { direction in
            guard let setIndex, count > 0 else { return }
            switch direction {
            case .increment: setIndex(CarouselIndex.clamped(current + 1, count: count))
            case .decrement: setIndex(CarouselIndex.clamped(current - 1, count: count))
            @unknown default: break
            }
        }
    }

    // MARK: - Styles

    private func dots(maximumVisible: Int) -> some View {
        let window = DotWindow(count: count, index: current, maximumVisible: maximumVisible)
        return HStack(spacing: Metrics.dotSpacing) {
            ForEach(Array(window.range), id: \.self) { page in
                Capsule()
                    .fill(page == current ? AnyShapeStyle(TintShapeStyle()) : AnyShapeStyle(TintShapeStyle().opacity(0.3)))
                    .frame(width: page == current ? Metrics.dot * 2.6 : Metrics.dot, height: Metrics.dot)
                    .scaleEffect(window.scale(of: page))
                    .contentShape(Rectangle().inset(by: -6))
                    .indicatorTap { select(page) }
            }
        }
        .padding(.vertical, 6)
    }

    private var line: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let thumb = count > 0 ? max(width / CGFloat(count), Metrics.lineHeight * 2) : 0
            let travel = width - thumb
            let offset = count > 1 ? travel * CGFloat(current) / CGFloat(count - 1) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(TintShapeStyle().opacity(0.25))
                Capsule().fill(.tint)
                    .frame(width: thumb)
                    .offset(x: offset)
            }
            #if !os(tvOS)
            .contentShape(Rectangle())
            .onTapGesture { location in
                guard width > 0, count > 0 else { return }
                select(Int(location.x / width * CGFloat(count)))
            }
            #endif
        }
        .frame(width: Metrics.lineWidth, height: Metrics.lineHeight)
        .padding(.vertical, 6)
    }

    private var numbered: some View {
        Text(PageIndicatorText.numbered(index: current, count: count))
            .font(Metrics.numberFont)
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(current)))
            .padding(.horizontal, Metrics.numberPadding)
            .padding(.vertical, Metrics.numberPadding / 2.4)
            .background(TintShapeStyle().opacity(0.22), in: Capsule())
    }

    private var progress: some View {
        HStack(spacing: Metrics.segmentSpacing) {
            ForEach(0..<count, id: \.self) { page in
                Capsule()
                    .fill(page <= current ? AnyShapeStyle(TintShapeStyle()) : AnyShapeStyle(TintShapeStyle().opacity(0.25)))
                    .frame(height: Metrics.lineHeight)
                    .contentShape(Rectangle().inset(by: -8))
                    .indicatorTap { select(page) }
            }
        }
        .frame(maxWidth: Metrics.progressWidth)
        .padding(.vertical, 6)
    }

    private func select(_ page: Int) {
        guard let setIndex, count > 0 else { return }
        setIndex(CarouselIndex.clamped(page, count: count))
    }
}

/// Sizes per platform: Apple TV is viewed from across the room.
private enum Metrics {
    #if os(tvOS)
    static let dot: CGFloat = 14
    static let dotSpacing: CGFloat = 14
    static let lineWidth: CGFloat = 360
    static let lineHeight: CGFloat = 8
    static let segmentSpacing: CGFloat = 10
    static let progressWidth: CGFloat = 640
    static let numberPadding: CGFloat = 22
    static var numberFont: Font { .system(size: 30, weight: .semibold, design: .rounded) }
    #else
    static let dot: CGFloat = 8
    static let dotSpacing: CGFloat = 8
    static let lineWidth: CGFloat = 120
    static let lineHeight: CGFloat = 4
    static let segmentSpacing: CGFloat = 5
    static let progressWidth: CGFloat = 320
    static let numberPadding: CGFloat = 12
    static var numberFont: Font { .system(.footnote, design: .rounded).weight(.semibold) }
    #endif
}

extension View {
    /// Taps on an indicator's dot or segment; Apple TV has no touch, so nothing there.
    @ViewBuilder
    fileprivate func indicatorTap(_ action: @escaping () -> Void) -> some View {
        #if os(tvOS)
        self
        #else
        onTapGesture(perform: action)
        #endif
    }
}
