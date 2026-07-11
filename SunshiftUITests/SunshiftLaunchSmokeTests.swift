import XCTest

/// Fresh-launch smoke test: get through onboarding (or confirm it's already
/// bypassed) and land on the Today tab. Not meant to cover onboarding in depth.
final class SunshiftLaunchSmokeTests: XCTestCase {

    /// Generous to stay robust on slower CI/simulator hosts; the flow itself is short.
    private let stepTimeout: TimeInterval = 15

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFreshLaunchReachesTodayTab() throws {
        let app = XCUIApplication()
        app.launch()

        completeOnboardingIfPresented(in: app)

        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.waitForExistence(timeout: stepTimeout), "Main tab bar with Today tab did not appear")
        todayTab.tap()

        XCTAssertTrue(
            app.navigationBars["Today"].waitForExistence(timeout: stepTimeout),
            "Today tab did not render its navigation title"
        )
    }

    /// Walks the current onboarding flow using its "skip" affordances so no
    /// system location/notification permission dialogs are triggered. If
    /// onboarding isn't showing (already completed in a prior run), returns.
    @MainActor
    private func completeOnboardingIfPresented(in app: XCUIApplication) {
        let getStarted = app.buttons["Get Started"]
        guard getStarted.waitForExistence(timeout: stepTimeout) else { return }
        getStarted.tap()

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: stepTimeout), "Template pick step did not appear")
        continueButton.tap()

        XCTAssertTrue(continueButton.waitForExistence(timeout: stepTimeout), "Customize step did not appear")
        continueButton.tap()

        let skipLocation = app.buttons["Skip for now"]
        XCTAssertTrue(skipLocation.waitForExistence(timeout: stepTimeout), "Location step did not appear")
        skipLocation.tap()

        XCTAssertTrue(continueButton.waitForExistence(timeout: stepTimeout), "Confirm step did not appear")
        continueButton.tap()

        let notNow = app.buttons["Not now"]
        XCTAssertTrue(notNow.waitForExistence(timeout: stepTimeout), "Notifications step did not appear")
        notNow.tap()
    }
}
