import SwiftUI
import SwiftData

/// Transparent PNGs of the widgets and the menu bar extra, for the shared `widget-screenshots` in
/// Repos/Scripts to lay out on wallpapers for the listing.
///
/// Switched on by `-widgetShots` alongside `-screenshotMode`. Neither surface can be photographed by
/// a UI test — widgets live on a Home Screen the test does not own, and the menu bar is outside any
/// window — so the app draws the same views itself, from the same seed the walk uses, and exits. The
/// iPhone draws the widgets, since the Lock Screen families exist only there; the Mac draws the menu
/// bar. Each image leaves on stdout as `WIDGETSHOT<tab>name<tab>scale<tab>base64 png` — stdout
/// because a sandboxed Mac app has no folder the script can also reach.
///
/// The one exception is Liquid Glass, which only the window server draws. Under `-glassTile` the Mac
/// takes a finished shot on stdin, lays the open menu on real glass over it in an on-screen window,
/// captures the window, and prints the whole shot back — see `renderGlass()`.
///
/// None of this is the system's own rendering: corner radii and margins are estimates, the Lock
/// Screen's vibrant monochrome is approximated as plain white, and the menu is a look-alike of the
/// one AppKit draws for `MenuBarEventsMenu`.
enum WidgetShots {

    @MainActor
    static func renderIfRequested() {
        guard ScreenshotMode.isActive, ProcessInfo.processInfo.arguments.contains("-widgetShots") else { return }
        #if os(iOS)
        renderWidgets()
        #elseif os(macOS)
        if ProcessInfo.processInfo.arguments.contains("-glassTile") { renderGlass() } else { renderMenuBar() }
        #endif
        exit(0)
    }

    private static func emit(_ png: Data?, _ name: String, scale: Double) {
        guard let png else { return print("WIDGETSHOT-FAILED\t\(name)") }
        print("WIDGETSHOT\t\(name)\t\(scale)\t\(png.base64EncodedString())")
    }

    /// The seeded countdowns, the way the widget's timeline provider picks them.
    @MainActor
    private static var events: [Event] {
        let events = Array(((try? ScreenshotMode.container.mainContext.fetch(FetchDescriptor<Event>())) ?? []).upcoming.prefix(6))
        // The provider downloads posters ahead of time, since a widget cannot load them itself; the
        // seeded one is a file in the bundle.
        for event in events {
            if case .remote(let url) = event.icon, url.isFileURL {
                event.preloadedIconData = try? Data(contentsOf: url)
            }
        }
        return events
    }

    #if os(iOS)

    // MARK: - Widgets

    /// iPhone 6.9" widget sizes, which the composer's grid is built around.
    private static let small = CGSize(width: 170, height: 170)
    private static let medium = CGSize(width: 364, height: 170)
    private static let large = CGSize(width: 364, height: 382)

    private static let circular = CGSize(width: 76, height: 76)
    private static let rectangular = CGSize(width: 172, height: 76)
    private static let inline = CGSize(width: 234, height: 26)

    @MainActor
    private static func renderWidgets() {
        let events = events

        // The widget's own container backgrounds: grouped grey in light, black at half strength
        // over the wallpaper in dark.
        for (look, scheme, color) in [("Light", ColorScheme.light, Color(uiColor: .systemGroupedBackground)),
                                      ("Dark", .dark, Color.black.opacity(0.5))] {
            func home(_ content: some View, _ size: CGSize, _ name: String) {
                save(tile(content, size, scheme, color), "Home Screen/\(name) \(look)")
            }
            home(CountdownsSmallWidget(events: events), small, "Small")
            home(CountdownsListWidget(events: events, isMedium: true), medium, "Medium")
            home(CountdownsListWidget(events: events, isMedium: false), large, "Large")
        }

        save(lock(CountdownsCircularAccessory(events: events), circular), "Lock Screen/Circular")
        save(lock(CountdownsRectangularAccessory(events: events), rectangular), "Lock Screen/Rectangular")
        save(lock(CountdownsInlineAccessory(events: events).font(.system(size: 17, weight: .semibold)), inline), "Lock Screen/Inline")
        save(lockScreen(events), "Lock Screen/Lock Screen")
    }

    /// The accessories where the Lock Screen puts them — the inline one beside the date above the
    /// clock, the others in the row beneath it — since on their own they read as stray white text.
    private static func lockScreen(_ events: [Event]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(Date.now, format: .dateTime.weekday(.abbreviated).day())
                CountdownsInlineAccessory(events: events)
            }
            .font(.system(size: 20, weight: .semibold))
            .lineLimit(1)
            Text("9:41")
                .font(.system(size: 96, weight: .semibold, design: .rounded))
                .monospacedDigit()
            HStack(spacing: 16) {
                CountdownsRectangularAccessory(events: events)
                    .frame(width: rectangular.width, height: rectangular.height)
                CountdownsCircularAccessory(events: events)
                    .frame(width: circular.width, height: circular.height)
            }
        }
        .frame(width: medium.width)
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }

    /// A Home Screen tile: the widget's own padding and a continuous-corner card.
    private static func tile(_ content: some View, _ size: CGSize, _ scheme: ColorScheme, _ color: Color) -> some View {
        content
            .padding(16)
            .frame(width: size.width, height: size.height)
            .background(color)
            .clipShape(.rect(cornerRadius: 24, style: .continuous))
            .accentColor(Color("AccentColor"))
            .environment(\.colorScheme, scheme)
    }

    /// White on transparent, the way the Lock Screen tints an accessory.
    private static func lock(_ content: some View, _ size: CGSize) -> some View {
        Color.white
            .mask {
                content
                    .frame(width: size.width, height: size.height)
                    .environment(\.colorScheme, .dark)
            }
            .frame(width: size.width, height: size.height)
    }

    @MainActor
    private static func save(_ view: some View, _ name: String) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        renderer.isOpaque = false
        emit(renderer.uiImage?.pngData(), name, scale: renderer.scale)
    }

    #elseif os(macOS)

    // MARK: - Menu bar

    @MainActor
    private static func renderMenuBar() {
        let events = events

        // Only its size and place in the layout: the composer leaves its spot bare for
        // `renderGlass()` to fill.
        let (png, scale) = snapshot(menuBarExtra(events, onGlass: false), appearance: NSAppearance(named: .darkAqua))
        emit(png, "Menu Bar/Menu Bar Extra", scale: scale)

        for (look, appearanceName) in [("Light", NSAppearance.Name.aqua), ("Dark", .darkAqua)] {
            let appearance = NSAppearance(named: appearanceName)
            let (png, scale) = snapshot(MenuLookalike(events: events).padding(5).background(.regularMaterial, in: .rect(cornerRadius: 12)), appearance: appearance)
            emit(png, "Menu Bar/Menu \(look)", scale: scale)

            let item = MenuBarLabel()
                .foregroundStyle(look == "Dark" ? Color.white : Color.black)
                .padding(.horizontal, 6)
                .frame(height: 24)
                .modelContainer(ScreenshotMode.container)
            let (itemPNG, itemScale) = snapshot(item, appearance: appearance)
            emit(itemPNG, "Menu Bar/Menu Bar Item \(look)", scale: itemScale)
        }
    }

    /// The extra open: its item highlighted in the menu bar, with the menu hanging below it. White on
    /// clear glass, whatever the appearance — only the glass itself stays light, which keeps it from
    /// tinting the wallpaper either way.
    @MainActor @ViewBuilder
    private static func menuBarExtra(_ events: [Event], onGlass: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            MenuBarLabel()
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(.white.opacity(0.25), in: .capsule)
                .padding(.leading, 12)
                .modelContainer(ScreenshotMode.container)
            if onGlass {
                MenuLookalike(events: events)
                    .padding(5)
                    .environment(\.colorScheme, .dark)
                    .glassEffect(.clear, in: .rect(cornerRadius: 12))
                    .environment(\.colorScheme, .light)
            } else {
                MenuLookalike(events: events)
                    .padding(5)
            }
        }
        .environment(\.colorScheme, .dark)
    }

    /// `MenuBarEventsMenu` as AppKit draws it — its Buttons become `NSMenuItem`s, which no SwiftUI
    /// renderer can draw, so this repeats its rows with the same data.
    private struct MenuLookalike: View {

        let events: [Event]

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(events.prefix(6)) { event in
                    row("\(event.daysUntilString)d  \(event.title ?? "")", event.menuBarSymbolName)
                }
                Divider()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                row("Open Countdowns", "macwindow")
                row("Quit Countdowns", "power", shortcut: "⌘Q")
            }
            .font(.system(size: 13))
            .frame(width: 240)
        }

        private func row(_ title: String, _ symbol: String, shortcut: String? = nil) -> some View {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .frame(width: 16)
                Text(title)
                    .lineLimit(1)
                Spacer()
                if let shortcut {
                    Text(shortcut)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 24)
        }
    }

    /// Lays `-glassTile` on real glass over the shot on stdin, where `-glassFrame` (canvas pixels)
    /// puts it at `-glassScale` pixels per point, and prints the whole shot back.
    ///
    /// The glass has to sit in a window over the real pixels to bend them, so the window holds the
    /// shot's pixels around that frame with the tile on top, and is captured by the window server.
    @MainActor
    private static func renderGlass() {
        func argument(_ flag: String) -> String {
            let arguments = ProcessInfo.processInfo.arguments
            return arguments.firstIndex(of: flag).flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil } ?? ""
        }
        let name = argument("-glassTile")
        let frame = argument("-glassFrame").split(separator: ",").compactMap { Double($0) }
        let scale = Double(argument("-glassScale")) ?? 0
        let stdin = FileHandle.standardInput.readDataToEndOfFile()
        guard name.hasSuffix("Menu Bar Extra"), frame.count == 4, scale > 0,
              let source = CGImageSourceCreateWithData(stdin as CFData, nil),
              let canvas = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return emit(nil, name, scale: 1) }

        // Some of the shot beyond the tile, so the glass's edges bend real pixels too.
        let tile = CGRect(x: frame[0], y: frame[1], width: frame[2], height: frame[3])
        let area = tile.insetBy(dx: -48, dy: -48).integral.intersection(CGRect(x: 0, y: 0, width: canvas.width, height: canvas.height))
        guard let backdrop = canvas.cropping(to: area) else { return emit(nil, name, scale: 1) }

        let window = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: .aqua)
        window.level = .floating
        let pixels = window.backingScaleFactor
        let content = ZStack(alignment: .topLeading) {
            Image(decorative: backdrop, scale: pixels)
            menuBarExtra(events, onGlass: true)
                .fixedSize()
                .scaleEffect(scale / pixels, anchor: .topLeading)
                .offset(x: (tile.minX - area.minX) / pixels, y: (tile.minY - area.minY) / pixels)
        }
        window.contentView = NSHostingView(rootView: content)
        window.setFrame(CGRect(origin: NSScreen.main?.visibleFrame.origin ?? .zero, size: CGSize(width: area.width / pixels, height: area.height / pixels)), display: true)
        window.orderFrontRegardless()
        RunLoop.main.run(until: .now.addingTimeInterval(1.5))
        defer { window.orderOut(nil) }
        // Less a few pixels at each edge, where the window server draws the window's rim.
        let rim = 8.0
        guard let capture = captureWindow(window.windowNumber),
              case let ratio = Double(capture.width) / area.width,
              let glass = capture.cropping(to: CGRect(x: 0, y: 0, width: capture.width, height: capture.height).insetBy(dx: rim * ratio, dy: rim * ratio))
        else { return emit(nil, name, scale: 1) }

        guard let context = CGContext(data: nil, width: canvas.width, height: canvas.height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return emit(nil, name, scale: 1) }
        let height = Double(canvas.height)
        context.interpolationQuality = .high
        context.draw(canvas, in: CGRect(x: 0, y: 0, width: canvas.width, height: canvas.height))
        context.draw(glass, in: CGRect(x: area.minX, y: height - area.maxY, width: area.width, height: area.height).insetBy(dx: rim, dy: rim))
        emit(context.makeImage().flatMap { NSBitmapImageRep(cgImage: $0).representation(using: .png, properties: [:]) }, name, scale: 1)
    }

    /// `CGWindowListCreateImage` is marked unavailable in the SDK, but it still captures the app's own
    /// windows — glass and all — with no Screen Recording permission, which ScreenCaptureKit needs.
    /// Looked up at runtime so a macOS that drops it fails the shot rather than the build.
    private static func captureWindow(_ number: Int) -> CGImage? {
        typealias CreateImage = @convention(c) (CGRect, UInt32, UInt32, UInt32) -> Unmanaged<CGImage>?
        guard let symbol = dlsym(dlopen(nil, RTLD_NOW), "CGWindowListCreateImage") else { return nil }
        let createImage = unsafeBitCast(symbol, to: CreateImage.self)
        // Including just this window; ignoring its framing, at its best resolution.
        return createImage(.null, 1 << 3, UInt32(number), 1 << 0 | 1 << 3)?.takeRetainedValue()
    }

    /// Hosts the view in a real, never-shown window and caches its display: `ImageRenderer` leaves
    /// out materials, and `@Query` needs a run loop to fill.
    @MainActor
    private static func snapshot(_ view: some View, appearance: NSAppearance?) -> (png: Data?, scale: Double) {
        let host = NSHostingView(rootView: view)
        host.appearance = appearance
        host.frame = CGRect(origin: .zero, size: host.fittingSize)
        let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.contentView = host
        RunLoop.main.run(until: .now.addingTimeInterval(1))
        host.frame = CGRect(origin: .zero, size: host.fittingSize)
        host.layoutSubtreeIfNeeded()
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return (nil, 1) }
        host.cacheDisplay(in: host.bounds, to: rep)
        return (rep.representation(using: .png, properties: [:]), Double(rep.pixelsWide) / host.bounds.width)
    }

    #endif
}
