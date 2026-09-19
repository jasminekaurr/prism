// Summary: UI smoke tests for onboarding demo mode and core navigation identifiers.

import XCTest

final class PrismUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingDemoMode() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Advance onboarding pages if present
        let brand = app.staticTexts["onboarding.brand"]
        if brand.waitForExistence(timeout: 5) {
            let continueButton = app.buttons["onboarding.continue"]
            while continueButton.exists {
                continueButton.tap()
            }
            let demo = app.buttons["onboarding.demo"]
            XCTAssertTrue(demo.waitForExistence(timeout: 5))
            demo.tap()
        }

        // After onboarding, tabs should appear
        let home = app.tabBars.buttons["Home"]
        XCTAssertTrue(home.waitForExistence(timeout: 8))
    }

    func testCreateCollectionAndOpenCapture() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        completeOnboardingIfNeeded(app)

        app.tabBars.buttons["Collections"].tap()
        let create = app.buttons["collections.create"]
        if create.waitForExistence(timeout: 5) {
            create.tap()
            let name = app.textFields["collection.name"]
            if name.waitForExistence(timeout: 3) {
                name.tap()
                name.typeText("Summer Fashion")
                app.buttons["collection.save"].tap()
            }
        }

        app.tabBars.buttons["Home"].tap()
        let add = app.buttons["home.add"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        XCTAssertTrue(app.staticTexts["capture.title"].waitForExistence(timeout: 5))
    }

    private func completeOnboardingIfNeeded(_ app: XCUIApplication) {
        let brand = app.staticTexts["onboarding.brand"]
        guard brand.waitForExistence(timeout: 3) else { return }
        let continueButton = app.buttons["onboarding.continue"]
        while continueButton.exists {
            continueButton.tap()
        }
        if app.buttons["onboarding.demo"].exists {
            app.buttons["onboarding.demo"].tap()
        }
        _ = app.tabBars.buttons["Home"].waitForExistence(timeout: 8)
    }
}
