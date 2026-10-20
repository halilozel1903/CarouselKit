import SwiftUI
import CarouselKit

/// A destination card of the demo. Everything here is made up for the example app: the names are
/// generic landscape descriptions, not real places, and the art is gradient illustrations bundled
/// in `Art.xcassets`, generated for this demo. Nothing is loaded from the network.
struct DemoDestination: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let kind: String
    let tagline: String
    let nights: Int
    let season: String
    let summary: String
    let accent: Color

    /// The bundled illustration.
    var art: Image { Image(id) }
}

extension DemoDestination {
    /// The demo's eight destinations, in carousel order.
    static let all: [DemoDestination] = [
        DemoDestination(
            id: "coral-lagoon", name: "Coral Lagoon", kind: "Coast",
            tagline: "Warm water and long sunsets", nights: 5, season: "Summer",
            summary: "A shallow turquoise lagoon for snorkeling mornings and slow evenings on the sand.",
            accent: Color(red: 1.0, green: 0.55, blue: 0.48)
        ),
        DemoDestination(
            id: "alpine-lakes", name: "Alpine Lakes", kind: "Mountains",
            tagline: "Snowy peaks over still water", nights: 4, season: "Late summer",
            summary: "Lakeside trails under snowy peaks, with cabins and cold, clear swims.",
            accent: Color(red: 0.45, green: 0.72, blue: 1.0)
        ),
        DemoDestination(
            id: "dune-sea", name: "Dune Sea", kind: "Desert",
            tagline: "Golden hour on the dunes", nights: 3, season: "Spring",
            summary: "Rolling dunes, camp under the stars and a sunrise walk along the ridges.",
            accent: Color(red: 1.0, green: 0.7, blue: 0.38)
        ),
        DemoDestination(
            id: "northern-lights", name: "Northern Lights", kind: "Arctic",
            tagline: "Aurora over snowy hills", nights: 6, season: "Winter",
            summary: "Long nights for aurora watching, snowshoe walks and a sauna by the trees.",
            accent: Color(red: 0.36, green: 0.96, blue: 0.72)
        ),
        DemoDestination(
            id: "blossom-valley", name: "Blossom Valley", kind: "Countryside",
            tagline: "Hills in full bloom", nights: 4, season: "Spring",
            summary: "Picnics under blossom trees and bike rides along green, rolling hills.",
            accent: Color(red: 1.0, green: 0.6, blue: 0.78)
        ),
        DemoDestination(
            id: "misty-fjord", name: "Misty Fjord", kind: "Fjord",
            tagline: "Sailing between the cliffs", nights: 5, season: "Autumn",
            summary: "Quiet sailing in the fog between steep cliffs, with waterfalls around each bend.",
            accent: Color(red: 0.7, green: 0.82, blue: 0.92)
        ),
        DemoDestination(
            id: "canyon-trail", name: "Canyon Trail", kind: "Canyon",
            tagline: "Red rock and wide skies", nights: 3, season: "Autumn",
            summary: "A winding trail down layered red rock, with a night at the canyon floor.",
            accent: Color(red: 0.95, green: 0.48, blue: 0.3)
        ),
        DemoDestination(
            id: "moonlit-isles", name: "Moonlit Isles", kind: "Islands",
            tagline: "Island hopping by moonlight", nights: 7, season: "Summer",
            summary: "Small islands a short boat ride apart, best seen from the water at night.",
            accent: Color(red: 0.72, green: 0.68, blue: 1.0)
        ),
    ]
}

/// The look of "Wander", the demo app.
enum Theme {
    static let background = Color(red: 0.06, green: 0.06, blue: 0.11)
    static let surface = Color(red: 0.11, green: 0.11, blue: 0.18)
    static let accent = Color(red: 1.0, green: 0.55, blue: 0.48)
    /// The note shown wherever the demo content appears.
    static let demoNote = "Demo content: generated art, not real places"
}

/// A small "DEMO" capsule for the cards.
struct DemoBadge: View {
    var size: CGFloat = 11

    var body: some View {
        Text("DEMO")
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .tracking(size * 0.12)
            .foregroundStyle(.white)
            .padding(.horizontal, size * 0.8)
            .padding(.vertical, size * 0.35)
            .background(.black.opacity(0.35), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1))
    }
}

/// A destination's art, filling its frame. In a `.parallax` carousel it moves slower than the
/// card (`.carouselParallax()`).
struct DestinationArt: View {
    let destination: DemoDestination

    var body: some View {
        Color.clear
            .overlay {
                destination.art
                    .resizable()
                    .scaledToFill()
            }
            .carouselParallax()
            .clipped()
            .accessibilityHidden(true)
    }
}
