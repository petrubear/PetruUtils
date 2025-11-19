import XCTest
import AppKit
@testable import PetruUtils

@MainActor
final class ClipboardMonitorTests: XCTestCase {

    var monitor: ClipboardMonitor!
    var pasteboard: NSPasteboard!

    override func setUp() {
        super.setUp()
        pasteboard = NSPasteboard.general
        // Clear pasteboard to isolate tests
        pasteboard.clearContents()
        monitor = ClipboardMonitor(pasteboard: pasteboard)
    }

    override func tearDown() {
        monitor = nil
        pasteboard = nil
        super.tearDown()
    }

    func testDetectsJSON() {
        let json = "{\"key\": \"value\"}"
        _ = pasteboard.writeObjects([json as NSString])

        monitor.checkClipboard()

        XCTAssertEqual(monitor.lastDetectedType, .json)
        XCTAssertEqual(monitor.lastContent, json)
    }

    func testDetectsURL() {
        let url = "https://example.com"
        _ = pasteboard.writeObjects([url as NSString])

        monitor.checkClipboard()

        XCTAssertEqual(monitor.lastDetectedType, .url)
        XCTAssertEqual(monitor.suggestedTool, .urlEncoder)
    }

    func testIgnoresEmptyContent() {
        _ = pasteboard.writeObjects(["" as NSString])

        monitor.checkClipboard()

        XCTAssertNil(monitor.lastDetectedType)
    }

    func testOnlyChecksOnChange() {
        let json = "{\"key\": \"value\"}"
        _ = pasteboard.writeObjects([json as NSString])

        monitor.checkClipboard()

        XCTAssertEqual(monitor.lastContent, json)

        let lastDetectedType = monitor.lastDetectedType

        // We don't change the pasteboard, so the changeCount should be the same
        monitor.checkClipboard()

        // Should not have updated because changeCount is the same
        XCTAssertEqual(monitor.lastDetectedType, lastDetectedType)
    }
}
