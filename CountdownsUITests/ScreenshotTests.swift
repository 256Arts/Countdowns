import XCTest
#if canImport(UIKit)
import UIKit
#endif

/// Drives the app through the screens that become App Store screenshots and attaches each one to the
/// result bundle, where the shared `screenshots` runner collects them.
///
/// One test rather than one per screen: the shots are a walk through a single launch, and splitting
/// them would pay the launch — and the reseed — every time.
@MainActor
final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    /// Whether the walk turned the device on its side, which the capture has to undo.
    ///
    /// Tracked here rather than read back from `XCUIDevice.shared.orientation`, which a simulator
    /// answers from a device that is not being held and reports as portrait however the UI is laid
    /// out — so the capture believed every shot was already upright.
    private var isLandscape = false

    func testCaptureAppStoreScreenshots() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-screenshotMode"]
        app.launch()

        #if os(macOS)
        openWindowIfNeeded()
        #endif

        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            // The iPad listing opens with a hand-made widget shot that is landscape, and a store
            // gallery that changes shape between slots looks like a mistake. Landscape is the better
            // half of the trade anyway: it is the shape a 13" iPad is held in, and the one that
            // gives the split view's two columns room.
            XCUIDevice.shared.orientation = .landscapeLeft
            isLandscape = true
            settle()
        }
        #endif

        #if os(visionOS)
        // visionOS puts the sidebar in an ornament whose rows never reach the accessibility tree, so
        // the walk has nothing to drive there. It waits on the seeded selection in the detail column
        // instead and takes the one shot; `simctl io screenshot` captures the ornament along with
        // the window, so the list is in the picture either way.
        let seeded = element("Flight to Tokyo")
        #else
        // A seeded countdown. Waiting on it means the capture cannot beat the data on screen; this
        // one repeats yearly, so its detail screen has the "Repeats Yearly" line to show as well.
        let seeded = element("EventRow.Mom's Birthday")
        #endif
        guard seeded.waitForExistence(timeout: 30) else {
            attach(XCTAttachment(string: app.debugDescription), named: "element-tree")
            return XCTFail("seeded content never appeared")
        }
        settle()
        // The captures are named in listing order, not walk order: the runner files them by sorted
        // attachment name, so the walk is free to take them in whatever order needs the fewest
        // steps. Slot 1 of the iPhone and iPad listings is the hand-made widget shot, which no run
        // takes — see MANUAL_SHOTS in .screenshots.conf.
        //
        // The list earns a shot of its own only where it is the whole screen. A split view keeps it
        // in the sidebar of every other shot the walk takes, so the iPad and the Mac would be
        // spending a slot on something their other shots already show. visionOS is the exception
        // that keeps this shot: it is the only one that platform can take.
        #if os(visionOS)
        capture("03-upcoming")
        #elseif os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            capture("03-upcoming")
        }
        #endif

        // The sheet comes first so the walk reaches it without navigating back — the list's toolbar
        // is only on the list. The Mac takes it too: macOS hangs a sheet off its parent window, so
        // the `screencapture -l` of one photographs the pair. A popover is not attached that way,
        // which is why the editor shot below is the one the Mac still cannot take.
        #if !os(visionOS)
        openAddMenu()
        activate(element("Import Calendar"), "the Import Calendar menu item")
        settle()
        // Pick one, so the shot shows the screen mid-decision rather than untouched with its Import
        // button greyed out.
        activate(element("Calendar.Family"), "the Family calendar")
        settle(seconds: 1)
        capture("05-import-calendar")
        activate(element("Cancel"), "the Import Calendar Cancel button")
        settle()
        #endif

        #if !os(visionOS)
        activate(element("EventRow.The Chronos Project"), "the movie countdown")
        settle()
        capture("02-movie")
        #endif

        // The editor belongs on a countdown the user made. The demo's movie is a plain countdown
        // wearing a poster and so offers an Edit button, but a real TMDB release does not
        // (`Event.isEditable`) — taking the shot there would advertise a button the app withholds
        // from exactly the screen in the picture. The Mac's editor shot is hand-made instead
        // (MAC_MANUAL_SHOTS), so the walk leaves that slot alone.
        #if !os(macOS) && !os(visionOS)
        returnToList()
        activate(seeded, "the birthday countdown")
        settle()
        activate(element("Edit"), "the Edit button")
        settle()
        capture("04-edit")
        #endif
    }

    #if os(macOS)
    /// Opens a window when the launch came up without one.
    ///
    /// `XCUIApplication.launch()` launches a Mac app in the *background*, and AppKit gives a
    /// background launch no window — it holds it until the user arrives. The app comes up as a menu
    /// bar and nothing else, every lookup in the walk comes back empty, and the run dies on the
    /// first wait with the seed sitting in a store no window is showing. `activate()` is not what
    /// AppKit waits for: only a reopen, the event a Dock icon click sends, builds the window, and a
    /// test runner has no way to send one — so the walk asks for the window itself, with the app's
    /// own New Window.
    ///
    /// Whether a launch gets away without this depends on who started the run: LaunchServices
    /// activates a launched app only while the process that launched it is frontmost, so the same
    /// walk comes up with a window when it is run by hand from a frontmost Terminal and with
    /// nothing but a menu bar when an agent runs it in the background.
    ///
    /// Waits first rather than counting windows straight after `launch()`, which returns on idle
    /// and can beat the window into the accessibility tree — ⌘N would then open a second, empty one
    /// and the walk would photograph that.
    private func openWindowIfNeeded() {
        if app.windows.firstMatch.waitForExistence(timeout: 10) { return }
        app.typeKey("n", modifierFlags: .command)
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 15),
                      "the app launched with no window and ⌘N opened none")
    }
    #endif

    // MARK: - Driving

    /// Looks the element up by accessibility identifier *or* label, through the types it can turn up
    /// as: a countdown row is a button on one platform and a cell on another, a menu item is a
    /// `MenuItem` on the Mac and a `Button` on iOS, and a row of an inline `Picker` is a `RadioButton`
    /// on the Mac where iOS gives a cell.
    ///
    /// `staticTexts` comes after all of those on purpose. A row's label matches its text as readily
    /// as the control around it, and clicking the text does nothing — which is silent, since the
    /// click lands somewhere real and only the screenshot shows nothing was selected.
    ///
    /// `element(boundBy: 0)` rather than `firstMatch`, which can short-circuit resolution and report
    /// `exists == false` for an element the same query plainly matches.
    private func element(_ name: String) -> XCUIElement {
        let queries = [app.buttons, app.cells, app.radioButtons, app.menuItems, app.staticTexts, app.otherElements]
        for query in queries {
            for candidate in [query.matching(identifier: name).element(boundBy: 0),
                              query.matching(NSPredicate(format: "label == %@", name)).element(boundBy: 0)]
            where candidate.exists {
                return candidate
            }
        }
        return app.descendants(matching: .any).matching(identifier: name).element(boundBy: 0)
    }

    private func activate(_ element: XCUIElement, _ description: String) {
        guard element.waitForExistence(timeout: 15) else {
            attach(XCTAttachment(string: app.debugDescription), named: "element-tree")
            return XCTFail("never found \(description)")
        }
        #if os(macOS)
        element.click()
        #else
        element.tap()
        #endif
    }

    /// Leaves the detail screen, so the walk can open a different countdown.
    ///
    /// Only a stack pushed one — a split view has the list beside the detail the whole time, and
    /// tapping what it offers as a back button there would collapse the sidebar instead. Whether a
    /// row is still reachable is the reliable way to tell the two apart, and it needs no knowledge of
    /// which toolbar item sits where on which platform.
    private func returnToList() {
        guard !element("EventRow.Mom's Birthday").isHittable else { return }

        activate(app.navigationBars.buttons.element(boundBy: 0), "the back button")
        settle()
    }

    /// The `+` toolbar menu, which every "add an event" sheet hangs off.
    private func openAddMenu() {
        activate(element("Add"), "the Add menu")
        settle(seconds: 1)
    }

    /// Animations and async content have no element to wait on, so the shots pause instead.
    private func settle(seconds: TimeInterval = 2) {
        Thread.sleep(forTimeInterval: seconds)
    }

    // MARK: - Capturing

    private func capture(_ name: String) {
        // Every capture below photographs the whole screen, or the frontmost window — never this
        // app in particular. So an app that has lost the foreground yields another app's UI, filed
        // under this app's name, at the right size, with nothing to notice. The shared runner holds
        // a machine-wide lock so that cannot happen; this is the check that it held.
        XCTAssertEqual(app.state, .runningForeground,
                       "\(name): the app under test was not frontmost — another app has this device")
        #if os(macOS)
        captureExternally(named: name)
        #elseif os(visionOS)
        // visionOS has no screen for `XCUIScreen.main.screenshot()` to return, so the runner takes
        // the shot from outside with `simctl io screenshot`.
        captureExternally(named: name)
        #else
        // The simulator's screen already *is* the store's canvas, at the exact required pixel size.
        attach(upright(XCUIScreen.main.screenshot()), named: name)
        #endif
    }

    #if os(iOS)

    /// The screenshot, turned the way the device is being held.
    ///
    /// `XCUIScreen.main.screenshot()` photographs the *physical* screen, so a device the walk rotated
    /// comes back as a portrait buffer carrying its quarter turn as orientation metadata — and the
    /// PNG `XCTAttachment(screenshot:)` writes is that raw buffer, content on its side. Nothing
    /// downstream straightens it: the runner files whatever it is handed, and the store would publish
    /// a picture readable only sideways.
    ///
    /// Redrawing is what bakes the metadata into the pixels. `UIImage.size` is already the turned
    /// size and `draw(at:)` already honours the orientation, so a canvas of the image's own size and
    /// a plain draw is the whole rotation — turning it by hand as well would only turn it back.
    private func upright(_ screenshot: XCUIScreenshot) -> XCTAttachment {
        guard isLandscape else {
            return XCTAttachment(screenshot: screenshot)
        }

        let image = screenshot.image
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale   // keep the pixel count the store checks against
        format.opaque = true
        let rotated = UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(at: .zero)
        }
        return XCTAttachment(image: rotated)
    }

    #endif

    private func attach(_ attachment: XCTAttachment, named name: String) {
        attachment.name = name
        attachment.lifetime = .keepAlways   // attachments on a passing test are discarded otherwise
        add(attachment)
    }

    #if os(macOS) || os(visionOS)

    /// Asks the shell running the tests to photograph the app, and waits for it.
    ///
    /// On the Mac the good capture is `screencapture -l`, which reads the window's own buffer:
    /// correctly masked to the rounded corners, with real alpha and the system's own shadow.
    /// (`XCUIElement.screenshot()` crops the *screen* to the window's frame, so it loses the shadow —
    /// drawn outside that frame — and leaves desktop inside the corners.) But `screencapture` needs
    /// Screen Recording, which the test runner has no grant for and the terminal running the script
    /// does. So the test drives the UI and the script takes the picture.
    ///
    /// They meet in a plain directory under /tmp, which works only because the runner is deliberately
    /// unsandboxed (UITests.entitlements): a sandboxed runner cannot write /tmp, and its own container
    /// is unreadable to the script, so the two would have nowhere to meet.
    private static let handshakeDirectory = URL(fileURLWithPath: "/tmp/app-store-screenshots")

    private func captureExternally(named name: String) {
        let files = FileManager.default
        let handshake = Self.handshakeDirectory
        let done = handshake.appendingPathComponent("done-\(name)")
        try? files.removeItem(at: done)

        let request = handshake.appendingPathComponent("request-\(name)")
        guard files.createFile(atPath: request.path, contents: nil) else {
            return XCTFail("could not write a capture request to \(request.path)")
        }

        let deadline = Date().addingTimeInterval(30)
        while Date() < deadline {
            if files.fileExists(atPath: done.path) { return }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTFail("timed out waiting for the script to capture \(name) — is the runner watching \(handshake.path)?")
    }

    #endif
}
