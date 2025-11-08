//
//  PetruUtilsUITestsLaunchTests.swift
//  PetruUtilsUITests
//
//  Created by Edison Martinez on 2/10/25.
//

import XCTest

final class PetruUtilsUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // UI tests disabled - focusing on service-level unit tests only
    // Uncomment if needed for UI testing in the future
    
    /*
    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    */
}
