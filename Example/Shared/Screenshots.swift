import Foundation
import SwiftUI

/// Scenes used by CI to capture the README screenshots. Launch with `-screenshot <scene>`; normal
/// launches are unaffected.
///
/// CarouselKit is a UI library, so the scenes show its carousels over the example app's bundled
/// demo destinations (generic names, generated gradient art; see `DemoDestination`). Nothing is
/// loaded from the network. Auto scroll is off in the scenes so every capture shows the same page.
enum ScreenshotScene: String {
    /// iPhone: the `.scaled` style with dots, on the third destination.
    case scaled
    /// iPhone: the `.parallax` style with the "2 / 8" numbered indicator.
    case parallax
    /// iPhone: the `.stacked` style with the progress indicator.
    case stacked
    /// Apple TV: the focus-driven carousel on the third destination.
    case carousel

    static var current: ScreenshotScene? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshot"), arguments.indices.contains(index + 1) else {
            return nil
        }
        var name = arguments[index + 1]
        for prefix in ["iphone-", "tv-"] where name.hasPrefix(prefix) {
            name.removeFirst(prefix.count)
        }
        return ScreenshotScene(rawValue: name)
    }

    /// The page the scene opens on.
    var initialIndex: Int {
        switch self {
        case .scaled: 2
        case .parallax: 1
        case .stacked: 0
        case .carousel: 2
        }
    }
}

extension View {
    /// Tells scripts/screenshots.sh that the scene is on screen by writing `tmp/screenshot-ready`
    /// into the app container, once the carousel has scrolled to its page and focus (Apple TV) has
    /// settled. The art is bundled, so there is nothing to wait for on the network.
    func signalsScreenshotReady(_ scene: ScreenshotScene?) -> some View {
        task {
            guard let scene else { return }
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            let marker = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("screenshot-ready")
            do {
                try scene.rawValue.write(to: marker, atomically: true, encoding: .utf8)
                print("Screenshot scene \(scene.rawValue) is ready")
            } catch {
                print("Could not write the screenshot marker: \(error)")
            }
        }
    }
}
