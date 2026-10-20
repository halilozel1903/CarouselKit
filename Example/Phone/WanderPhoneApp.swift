import CarouselKit
import SwiftUI

@main
struct WanderPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            PhoneHomeView(scene: ScreenshotScene.current)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}

/// The four carousel styles, as the demo's picker offers them.
enum DemoStyle: String, CaseIterable, Identifiable {
    case plain = "Plain"
    case scaled = "Scaled"
    case parallax = "Parallax"
    case stacked = "Stacked"

    var id: String { rawValue }

    var carouselStyle: CarouselStyle {
        switch self {
        case .plain: .plain
        case .scaled: .scaled
        case .parallax: .parallax
        case .stacked: .stacked
        }
    }

    /// Each style shows off another page indicator.
    var indicator: PageIndicatorStyle {
        switch self {
        case .plain: .line
        case .scaled: .dots
        case .parallax: .numbered
        case .stacked: .progress
        }
    }

    init(scene: ScreenshotScene?) {
        switch scene {
        case .parallax: self = .parallax
        case .stacked: self = .stacked
        default: self = .scaled
        }
    }
}

/// One screen: a style picker, the carousel of demo destinations, its page indicator and the
/// current destination's details, which follow the carousel's bound index.
struct PhoneHomeView: View {
    let scene: ScreenshotScene?
    @State private var style: DemoStyle
    @State private var index: Int

    private let destinations = DemoDestination.all

    init(scene: ScreenshotScene?) {
        self.scene = scene
        _style = State(initialValue: DemoStyle(scene: scene))
        _index = State(initialValue: scene?.initialIndex ?? 0)
    }

    private var current: DemoDestination {
        destinations[CarouselIndex.clamped(index, count: destinations.count)]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Picker("Style", selection: $style) {
                        ForEach(DemoStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    Carousel(destinations, index: $index, spacing: 14, peek: 26, style: style.carouselStyle) { destination in
                        PhoneDestinationCard(destination: destination)
                    }
                    .frame(height: 440)
                    // A new style starts over with fresh pages.
                    .id(style)

                    PageIndicator(count: destinations.count, index: $index, style: style.indicator)
                        .frame(maxWidth: .infinity)

                    PhoneDestinationDetails(destination: current)
                        .padding(.horizontal, 20)
                        .animation(.smooth, value: index)
                }
                .padding(.vertical, 12)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Theme.background)
            .navigationTitle("Wander")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DemoBadge()
                }
            }
        }
        .carouselLoops()
        // Auto scroll in normal launches; screenshot scenes stay on their page.
        .carouselAutoScroll(every: 4, resumeAfter: 6, isEnabled: scene == nil)
        .signalsScreenshotReady(scene)
    }
}

/// A portrait destination card: the art, a shade, the name and tagline.
struct PhoneDestinationCard: View {
    let destination: DemoDestination

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            DestinationArt(destination: destination)
            LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 6) {
                Text(destination.kind.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(destination.accent)
                Text(destination.name)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text(destination.tagline)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .foregroundStyle(.white)
            .padding(22)
        }
        .overlay(alignment: .topTrailing) {
            DemoBadge()
                .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(destination.name), \(destination.tagline). Demo destination")
    }
}

/// The current destination under the carousel.
struct PhoneDestinationDetails: View {
    let destination: DemoDestination

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(destination.name)
                    .font(.title3.weight(.semibold))
                Spacer()
                Text("\(destination.nights) nights")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(destination.accent)
            }
            Text(destination.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Label(destination.season, systemImage: "sun.max")
                Label(destination.kind, systemImage: "map")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            Text(Theme.demoNote)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
