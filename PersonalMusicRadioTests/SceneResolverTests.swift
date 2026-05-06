import XCTest
@testable import PersonalMusicRadio

final class SceneResolverTests: XCTestCase {
    private let resolver = SceneResolver()

    func testBeforeTenResolvesToMorning() {
        XCTAssertEqual(resolver.resolve(now: date(hour: 9, minute: 59), calendar: calendar), .morning)
    }

    func testWeekdayMorningAfterTenResolvesToWork() {
        XCTAssertEqual(resolver.resolve(now: date(hour: 10, minute: 0), calendar: calendar), .work)
        XCTAssertEqual(resolver.resolve(now: date(hour: 10, minute: 1), calendar: calendar), .work)
    }

    func testNoonFirstHalfHourResolvesToLunch() {
        XCTAssertEqual(resolver.resolve(now: date(hour: 12, minute: 0), calendar: calendar), .lunch)
        XCTAssertEqual(resolver.resolve(now: date(hour: 12, minute: 29), calendar: calendar), .lunch)
    }

    func testNoonSecondWindowResolvesToNap() {
        XCTAssertEqual(resolver.resolve(now: date(hour: 12, minute: 30), calendar: calendar), .nap)
        XCTAssertEqual(resolver.resolve(now: date(hour: 13, minute: 59), calendar: calendar), .nap)
    }

    func testAfternoonAfterNapResolvesToHappy() {
        XCTAssertEqual(resolver.resolve(now: date(hour: 14, minute: 0), calendar: calendar), .happy)
        XCTAssertEqual(resolver.resolve(now: date(hour: 16, minute: 30), calendar: calendar), .happy)
    }

    func testNextSceneChangeFollowsProgramBoundaries() {
        XCTAssertEqual(
            resolver.nextSceneChange(after: date(hour: 9, minute: 59, second: 58), calendar: calendar),
            date(hour: 10, minute: 0, second: 0)
        )
        XCTAssertEqual(
            resolver.nextSceneChange(after: date(hour: 10, minute: 0, second: 0), calendar: calendar),
            date(hour: 12, minute: 0, second: 0)
        )
        XCTAssertEqual(
            resolver.nextSceneChange(after: date(hour: 23, minute: 59, second: 58), calendar: calendar),
            nextDayDate(hour: 0, minute: 0, second: 0)
        )
    }

    func testProgramNamesMatchRadioConcept() {
        XCTAssertEqual(resolver.program(for: .morning).name, "Morning Warmup")
        XCTAssertEqual(resolver.program(for: .work).name, "Workday Focus")
        XCTAssertEqual(resolver.program(for: .lunch).name, "Lunch Table")
        XCTAssertEqual(resolver.program(for: .nap).name, "Light Nap")
        XCTAssertEqual(resolver.program(for: .happy).name, "Afternoon Lift")
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(hour: Int, minute: Int, second: Int = 0) -> Date {
        DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 4,
            day: 27,
            hour: hour,
            minute: minute,
            second: second
        ).date!
    }

    private func nextDayDate(hour: Int, minute: Int, second: Int = 0) -> Date {
        DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 4,
            day: 28,
            hour: hour,
            minute: minute,
            second: second
        ).date!
    }
}
