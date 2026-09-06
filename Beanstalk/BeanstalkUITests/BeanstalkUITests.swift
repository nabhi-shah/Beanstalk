//
//  BeanstalkUITests.swift
//  BeanstalkUITests
//
//  Created by Nabhi on 8/17/26.
//

import XCTest

final class BeanstalkUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testSaveToastOpensSavedTab() throws {
        let app = XCUIApplication()
        app.launch()
        try XCTUnwrap(app.buttons.matching(identifier: "Login").allElementsBoundByIndex.last).tap()
        let publication = app.staticTexts["Financial Times"].firstMatch
        XCTAssertTrue(publication.waitForExistence(timeout: 5))
        publication.tap()
        app.buttons["Next"].tap()

        let article = app.staticTexts["The Data Center Backlash Bursts Into the Midterms"].firstMatch
        XCTAssertTrue(article.waitForExistence(timeout: 8))
        article.tap()
        let save = app.buttons["Save article"].firstMatch
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        let hittable = NSPredicate(format: "hittable == true")
        expectation(for: hittable, evaluatedWith: save)
        waitForExpectations(timeout: 5)
        save.tap()

        let viewSaved = app.buttons["viewSavedToastButton"]
        XCTAssertTrue(viewSaved.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Article Saved"].exists)
        XCTAssertTrue(app.buttons["Unsave article"].firstMatch.exists)
        expectation(for: hittable, evaluatedWith: viewSaved)
        waitForExpectations(timeout: 3)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Article Saved toast"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        viewSaved.tap()

        XCTAssertTrue(app.staticTexts["New App Connects Local Farmers Directly With Consumers for Fresher Produce"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(viewSaved.exists)
    }
}
