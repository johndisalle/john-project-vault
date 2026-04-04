import XCTest
@testable import ProjectVault

final class BadgeTests: XCTestCase {

    func testAllBadgesHaveUniqueIds() {
        let ids = Badge.allBadges.map(\.id)
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All badge IDs should be unique")
    }

    func testBadgeLookupById() {
        let badge = Badge.badge(withId: "first_100")
        XCTAssertNotNil(badge)
        XCTAssertEqual(badge?.title, "Century")
    }

    func testBadgeLookupReturnsNilForInvalidId() {
        let badge = Badge.badge(withId: "nonexistent_badge")
        XCTAssertNil(badge)
    }

    func testAllBadgesHaveTitlesAndDescriptions() {
        for badge in Badge.allBadges {
            XCTAssertFalse(badge.title.isEmpty, "Badge \(badge.id) should have a title")
            XCTAssertFalse(badge.description.isEmpty, "Badge \(badge.id) should have a description")
            XCTAssertFalse(badge.icon.isEmpty, "Badge \(badge.id) should have an icon")
        }
    }
}
