import XCTest

/// Drives the app through the screens that become App Store screenshots and attaches each one to the
/// result bundle, where the shared `screenshots` runner collects them.
///
/// One test rather than one per screen: the shots are a walk through a single launch, and splitting
/// them would pay the launch — and the reseed — every time.
@MainActor
final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    func testCaptureAppStoreScreenshots() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-screenshotMode"]
        app.launch()

        #if os(macOS)
        openWindowIfNeeded()
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
        capture("01-upcoming")

        // The sheets come before the detail screen so the walk never has to navigate back: the back
        // button sits in a different column per platform, and picking the wrong one silently leaves
        // the walk somewhere it cannot find the toolbar. They are skipped on the Mac, where
        // `screencapture -l` photographs one window and a sheet is its own window — the shot would
        // arrive without the app around it.
        #if !os(macOS) && !os(visionOS)
        openAddMenu()
        activate(element("Common Event"), "the Common Event menu item")
        settle()
        capture("03-common-events")
        activate(element("Done"), "the Common Events Done button")
        settle()

        openAddMenu()
        activate(element("Custom"), "the Custom menu item")
        settle()
        capture("04-new-event")
        activate(element("Cancel"), "the New Event Cancel button")
        settle()
        #endif

        #if !os(visionOS)
        activate(seeded, "the birthday countdown")
        settle()
        capture("02-event")
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
    /// Waiting first rather than counting windows straight after `launch()`, which returns on idle
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
    /// as: a countdown row is a button on one platform and a cell on another, and a menu item is a
    /// `MenuItem` on the Mac and a `Button` on iOS.
    ///
    /// `element(boundBy: 0)` rather than `firstMatch`, which can short-circuit resolution and report
    /// `exists == false` for an element the same query plainly matches.
    private func element(_ name: String) -> XCUIElement {
        let queries = [app.buttons, app.cells, app.menuItems, app.staticTexts, app.otherElements]
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
        attach(XCTAttachment(screenshot: XCUIScreen.main.screenshot()), named: name)
        #endif
    }

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
