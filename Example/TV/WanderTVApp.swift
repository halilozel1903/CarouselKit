import CarouselKit
import SwiftUI

@main
struct WanderTVApp: App {
    var body: some Scene {
        WindowGroup {
            TVHomeView(scene: ScreenshotScene.current)
                .preferredColorScheme(.dark)
                .tint(.white)
        }
    }
}

/// A full-screen carousel of the demo destinations. Moving focus left and right pages the
/// carousel; clicking a card saves it. The background and details follow the bound index.
struct TVHomeView: View {
    let scene: ScreenshotScene?
    @State private var index: Int
    @State private var saved: Set<String> = []

    private let destinations = DemoDestination.all

    init(scene: ScreenshotScene?) {
        self.scene = scene
        _index = State(initialValue: scene?.initialIndex ?? 0)
    }

    private var current: DemoDestination {
        destinations[CarouselIndex.clamped(index, count: destinations.count)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 34) {
            header
                .padding(.horizontal, 90)

            Carousel(destinations, index: $index, spacing: 48, peek: 150, style: .scaled(minimumScale: 0.88, minimumOpacity: 0.55), onSelect: { toggleSaved($0) }) { destination in
                TVDestinationCard(destination: destination, isSaved: saved.contains(destination.id))
            }
            .frame(height: 560)

            HStack(alignment: .center, spacing: 32) {
                PageIndicator(count: destinations.count, index: index, style: .dots)
                PageIndicator(count: destinations.count, index: index, style: .numbered)
                Spacer()
                Text(Theme.demoNote)
                    .font(.system(size: 22))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.horizontal, 90)
        }
        .padding(.vertical, 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            ZStack {
                Theme.background
                current.art
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 70)
                    .opacity(0.45)
                    .animation(.smooth(duration: 0.6), value: index)
                LinearGradient(colors: [.black.opacity(0.2), .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
        }
        .carouselLoops()
        .carouselAutoScroll(every: 6, resumeAfter: 10, isEnabled: scene == nil)
        .signalsScreenshotReady(scene)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 22) {
            Text("Wander")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
            Text("Demo destinations")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            DemoBadge(size: 20)
        }
    }

    private func toggleSaved(_ destination: DemoDestination) {
        if saved.contains(destination.id) {
            saved.remove(destination.id)
        } else {
            saved.insert(destination.id)
        }
    }
}

/// A landscape destination card for Apple TV.
struct TVDestinationCard: View {
    let destination: DemoDestination
    let isSaved: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            DestinationArt(destination: destination)
            LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(destination.kind.uppercased())
                        .font(.system(size: 24, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(destination.accent)
                    Text(destination.name)
                        .font(.system(size: 58, weight: .bold, design: .rounded))
                    Text(destination.tagline + " · \(destination.nights) nights · " + destination.season)
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Label(isSaved ? "Saved" : "Save", systemImage: isSaved ? "heart.fill" : "heart")
                    .font(.system(size: 26, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.black.opacity(0.35), in: Capsule())
            }
            .foregroundStyle(.white)
            .padding(44)
        }
        .overlay(alignment: .topTrailing) {
            DemoBadge(size: 18)
                .padding(30)
        }
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(destination.name), \(destination.tagline). Demo destination")
    }
}
