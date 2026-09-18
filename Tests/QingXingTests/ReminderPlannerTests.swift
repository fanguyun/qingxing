import XCTest
import QingXingCore

final class ReminderPlannerTests: XCTestCase {
    private var calendar: Calendar!
    private var day: Date!

    override func setUp() {
        super.setUp()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = cal

        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        day = cal.date(from: components)!
    }

    private func minutes(_ dates: [Date]) -> [String] {
        dates.map { date in
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return String(format: "%02d:%02d", components.hour!, components.minute!)
        }
    }

    private func makeSettings(
        activeStart: String = "09:00",
        activeEnd: String = "18:00",
        interval: Int = 60,
        custom: [String] = [],
        lunchEnabled: Bool = false,
        lunchStart: String = "12:00",
        lunchEnd: String = "13:00"
    ) -> AppSettings {
        var settings = AppSettings.defaultSettings
        settings.activeStart = activeStart
        settings.activeEnd = activeEnd
        settings.intervalMinutes = interval
        settings.customTimes = custom
        settings.lunchEnabled = lunchEnabled
        settings.lunchStart = lunchStart
        settings.lunchEnd = lunchEnd
        return settings
    }

    func testFixedIntervalStepping() {
        let times = minutes(ReminderPlanner.fireTimes(
            on: day,
            settings: makeSettings(interval: 60),
            calendar: calendar
        ))
        XCTAssertEqual(times, [
            "09:00", "10:00", "11:00", "12:00", "13:00",
            "14:00", "15:00", "16:00", "17:00"
        ])
    }

    func testLunchFiltering() {
        let times = minutes(ReminderPlanner.fireTimes(
            on: day,
            settings: makeSettings(interval: 60, lunchEnabled: true, lunchStart: "12:00", lunchEnd: "13:00"),
            calendar: calendar
        ))
        XCTAssertFalse(times.contains("12:00"))
        XCTAssertTrue(times.contains("11:00"))
        XCTAssertTrue(times.contains("13:00"))
    }

    func testCustomPointsIncludedAndDeduped() {
        let times = minutes(ReminderPlanner.fireTimes(
            on: day,
            settings: makeSettings(interval: 60, custom: ["10:00", "10:30"]),
            calendar: calendar
        ))
        XCTAssertEqual(times.filter { $0 == "10:00" }.count, 1)
        XCTAssertTrue(times.contains("10:30"))
    }

    func testOutOfWindowCustomFiltered() {
        let times = minutes(ReminderPlanner.fireTimes(
            on: day,
            settings: makeSettings(custom: ["19:00"]),
            calendar: calendar
        ))
        XCTAssertFalse(times.contains("19:00"))
    }

    func testInvalidWindowYieldsEmpty() {
        let times = ReminderPlanner.fireTimes(
            on: day,
            settings: makeSettings(activeStart: "18:00", activeEnd: "09:00"),
            calendar: calendar
        )
        XCTAssertTrue(times.isEmpty)
    }

    func testZeroIntervalYieldsOnlyCustom() {
        let times = minutes(ReminderPlanner.fireTimes(
            on: day,
            settings: makeSettings(interval: 0, custom: ["10:00"]),
            calendar: calendar
        ))
        XCTAssertEqual(times, ["10:00"])
    }

    func testNextFireTimeSkipsPast() {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 10
        components.minute = 5
        let now = calendar.date(from: components)!

        let next = ReminderPlanner.nextFireTime(
            now: now,
            settings: makeSettings(interval: 60),
            calendar: calendar
        )
        XCTAssertEqual(calendar.dateComponents([.hour, .minute], from: next!).hour, 11)
    }
}
