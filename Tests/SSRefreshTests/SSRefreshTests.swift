import XCTest
@testable import SSRefresh

final class SSRefreshTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        Language.setPreferredLanguage(.japanses)
        XCTAssertEqual(Language.Key.HeaderIdleText.locaizedString, "下拉即可刷新数据")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
