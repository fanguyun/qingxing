import XCTest
import QingXingCore

final class ReminderHistoryTests: XCTestCase {
    func testCompletedAndSkippedCountsAccumulateByDay() {
        var history = ReminderHistory()

        history.recordCompleted(on: "2026-09-18")
        history.recordCompleted(on: "2026-09-18")
        history.recordSkipped(on: "2026-09-18")

        XCTAssertEqual(history.day(for: "2026-09-18").completed, 2)
        XCTAssertEqual(history.day(for: "2026-09-18").skipped, 1)
        XCTAssertEqual(history.totalCompleted, 2)
        XCTAssertEqual(history.totalSkipped, 1)
    }

    func testMissingDayDefaultsToZero() {
        let history = ReminderHistory()

        XCTAssertEqual(history.day(for: "2026-09-19").completed, 0)
        XCTAssertEqual(history.day(for: "2026-09-19").skipped, 0)
    }
}
