import XCTest

/// Photographs the watch app's one screen for the App Store, the way `CountdownsUITests` does for
/// every other platform — a separate bundle because a UI test bundle is bound to one app, and the
/// watch app is its own target.
///
/// The walk is a single shot: the watch app is the Upcoming list, and its rows go nowhere.
@MainActor
final class ScreenshotTests: XCTestCase {

    func testCaptureAppStoreScreenshots() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-screenshotMode"]
        app.launch()

        // A seeded countdown, so the capture cannot beat the data onto the screen.
        let seeded = app.staticTexts["Mom's Birthday"]
        guard seeded.waitForExistence(timeout: 60) else {
            let tree = XCTAttachment(string: app.debugDescription)
            tree.name = "element-tree"
            tree.lifetime = .keepAlways
            add(tree)
            return XCTFail("seeded content never appeared")
        }
        Thread.sleep(forTimeInterval: 2)   // the list's appearance animation has nothing to wait on

        XCTAssertEqual(app.state, .runningForeground,
                       "the app under test was not frontmost — another app has this device")
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "01-upcoming"
        shot.lifetime = .keepAlways   // attachments on a passing test are discarded otherwise
        add(shot)
    }
}
