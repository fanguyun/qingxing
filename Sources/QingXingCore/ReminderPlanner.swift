import Foundation

public enum TimeParser {
    public static func minutes(from string: String) -> Int? {
        let parts = string.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              hour >= 0, hour <= 23,
              minute >= 0, minute <= 59 else {
            return nil
        }
        return hour * 60 + minute
    }

    public static func string(fromMinutes minutes: Int) -> String {
        let clamped = max(0, min(minutes, 23 * 60 + 59))
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }
}

public enum ReminderPlanner {
    /// 返回指定日期当天所有需要提醒的时刻（已过滤时段外 / 午休、去重并按时间排序）。
    public static func fireTimes(on date: Date, settings: AppSettings, calendar: Calendar) -> [Date] {
        guard let start = TimeParser.minutes(from: settings.activeStart),
              let end = TimeParser.minutes(from: settings.activeEnd),
              start < end else {
            return []
        }

        var result = Set<Int>()

        if settings.intervalMinutes > 0 {
            var current = start
            while current < end {
                result.insert(current)
                current += settings.intervalMinutes
            }
        }

        for time in settings.customTimes {
            if let minute = TimeParser.minutes(from: time), minute >= start, minute < end {
                result.insert(minute)
            }
        }

        if settings.lunchEnabled {
            let lunchStart = TimeParser.minutes(from: settings.lunchStart)
            let lunchEnd = TimeParser.minutes(from: settings.lunchEnd)
            if let lunchStart, let lunchEnd, lunchStart < lunchEnd {
                result = result.filter { !(lunchStart <= $0 && $0 < lunchEnd) }
            }
        }

        let dayStart = calendar.startOfDay(for: date)
        return result.sorted().map { minute in
            dayStart.addingTimeInterval(TimeInterval(minute * 60))
        }
    }

    /// 下一次提醒（严格晚于 now），找不到返回 nil。
    public static func nextFireTime(now: Date, settings: AppSettings, calendar: Calendar) -> Date? {
        fireTimes(on: now, settings: settings, calendar: calendar)
            .first { $0 > now }
    }
}
