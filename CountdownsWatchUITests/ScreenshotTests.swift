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

        // What the app says it seeded, hung on its root view by `.screenshotModeStatus()`. Read
        // first: a seed that refused to run — because the store was not the throwaway one — would
        // otherwise surface below as a missing row, which says nothing about why.
        let statusLabel = app.descendants(matching: .any)["ScreenshotMode.Status"]
        // A SwiftUI `Text` reaches XCUITest as the element's value on some platforms and as its
        // label on others, so take whichever is filled in.
        let status: String
        if !statusLabel.waitForExistence(timeout: 60) {
            status = "no ScreenshotMode.Status element — add .screenshotModeStatus() to the watch app's root view"
        } else if let value = statusLabel.value as? String, !value.isEmpty {
            status = value
        } else {
            status = statusLabel.label
        }
        print("SCREENSHOT MODE: \(status)")
        XCTAssertTrue(status.hasPrefix("ready"),
                      "the app did not seed a throwaway store, so there is nothing to photograph — \(status)")

        // A seeded countdown, so the capture cannot beat the data onto the screen.
        let seeded = app.staticTexts["Mom's Birthday"]
        guard seeded.waitForExistence(timeout: 60) else {
            let tree = XCTAttachment(string: app.debugDescription)
            tree.name = "element-tree"
            tree.lifetime = .keepAlways
            add(tree)
            return XCTFail("""
                never found the seeded countdown in 60s on watchOS, \
                \(ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "this watch").
                The app reported: \(status)
                The screen at the time is attached as element-tree.
                """)
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
