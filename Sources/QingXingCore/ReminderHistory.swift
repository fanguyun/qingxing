import Foundation

public struct ReminderDay: Codable, Equatable {
    public var completed: Int
    public var skipped: Int

    public init(completed: Int = 0, skipped: Int = 0) {
        self.completed = completed
        self.skipped = skipped
    }
}

public struct ReminderHistory: Codable, Equatable {
    public private(set) var days: [String: ReminderDay]

    public init(days: [String: ReminderDay] = [:]) {
        self.days = days
    }

    public func day(for key: String) -> ReminderDay {
        days[key] ?? ReminderDay()
    }

    public var totalCompleted: Int {
        days.values.reduce(0) { $0 + $1.completed }
    }

    public var totalSkipped: Int {
        days.values.reduce(0) { $0 + $1.skipped }
    }

    public mutating func recordCompleted(on key: String) {
        var day = day(for: key)
        day.completed += 1
        days[key] = day
    }

    public mutating func recordSkipped(on key: String) {
        var day = day(for: key)
        day.skipped += 1
        days[key] = day
    }
}

public final class ReminderHistoryStore {
    private let fileURL: URL

    public init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        let directory = base.appendingPathComponent("QingXing", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent("history.json")
    }

    public func load() -> ReminderHistory {
        guard let data = try? Data(contentsOf: fileURL),
              let history = try? JSONDecoder().decode(ReminderHistory.self, from: data) else {
            return ReminderHistory()
        }
        return history
    }

    public func save(_ history: ReminderHistory) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(history) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    public func dayKey(for date: Date = Date()) -> String {
        Self.dayFormatter.string(from: date)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
