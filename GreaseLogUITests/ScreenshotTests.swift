import XCTest

/// Captures App Store screenshots. Run with scripts/screenshots.sh GreaseLog.
final class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testAppScreens() {
        let app = XCUIApplication()
        app.launchArguments = ["-unlock", "-resetData", "-sampleData", "-skipOnboarding", "-uiTesting"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Grease traps"].waitForExistence(timeout: 15))
        sleep(1)
        snap("01-traps", app)

        // The interceptor that is inside its interval and still over the quarter rule.
        app.staticTexts["Back lot interceptor"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Back lot interceptor"].waitForExistence(timeout: 5))
        sleep(1)
        snap("02-trap", app)

        // The manifests and the depth checks sit below the fold, and they are what a FOG
        // inspection actually asks to see.
        for _ in 0..<3 { app.swipeUp() }
        sleep(1)
        snap("03-manifests", app)

        let addCheck = app.buttons["Add a depth check"].firstMatch
        if addCheck.waitForExistence(timeout: 3) {
            addCheck.tap()
            if app.navigationBars["Depth check"].waitForExistence(timeout: 5) {
                sleep(1)
                snap("04-depth-check", app)
                app.buttons["Cancel"].firstMatch.tap()
            }
        }

        let done = app.buttons["Done"].firstMatch
        if done.exists { done.tap() }
        XCTAssertTrue(app.buttons["How do I use this app?"].waitForExistence(timeout: 5))
        app.buttons["How do I use this app?"].tap()
        sleep(1)
        snap("05-how-to", app)
    }

    func testPaywall() {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboarding", "-uiTesting", "-mockPrices"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Lifetime"].waitForExistence(timeout: 10))
        snap("paywall", app)
    }

    private func snap(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
