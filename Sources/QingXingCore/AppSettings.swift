import Foundation

public struct AppSettings: Codable, Equatable {
    public var activeStart: String
    public var activeEnd: String
    public var intervalMinutes: Int
    public var customTimes: [String]
    public var lunchEnabled: Bool
    public var lunchStart: String
    public var lunchEnd: String
    public var snoozeMinutes: Int
    public var launchAtLogin: Bool
    public var isPaused: Bool
    public var themeID: String
    public var hasCompletedOnboarding: Bool

    public init(
        activeStart: String = "09:00",
        activeEnd: String = "18:00",
        intervalMinutes: Int = 60,
        customTimes: [String] = [],
        lunchEnabled: Bool = true,
        lunchStart: String = "12:00",
        lunchEnd: String = "13:30",
        snoozeMinutes: Int = 10,
        launchAtLogin: Bool = false,
        isPaused: Bool = false,
        themeID: String = "sunrise",
        hasCompletedOnboarding: Bool = false
    ) {
        self.activeStart = activeStart
        self.activeEnd = activeEnd
        self.intervalMinutes = intervalMinutes
        self.customTimes = customTimes
        self.lunchEnabled = lunchEnabled
        self.lunchStart = lunchStart
        self.lunchEnd = lunchEnd
        self.snoozeMinutes = snoozeMinutes
        self.launchAtLogin = launchAtLogin
        self.isPaused = isPaused
        self.themeID = themeID
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    public static let defaultSettings = AppSettings()

    private enum CodingKeys: String, CodingKey {
        case activeStart, activeEnd, intervalMinutes, customTimes
        case lunchEnabled, lunchStart, lunchEnd
        case snoozeMinutes, launchAtLogin, isPaused, themeID, hasCompletedOnboarding
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activeStart = try container.decodeIfPresent(String.self, forKey: .activeStart) ?? "09:00"
        activeEnd = try container.decodeIfPresent(String.self, forKey: .activeEnd) ?? "18:00"
        intervalMinutes = try container.decodeIfPresent(Int.self, forKey: .intervalMinutes) ?? 60
        customTimes = try container.decodeIfPresent([String].self, forKey: .customTimes) ?? []
        lunchEnabled = try container.decodeIfPresent(Bool.self, forKey: .lunchEnabled) ?? true
        lunchStart = try container.decodeIfPresent(String.self, forKey: .lunchStart) ?? "12:00"
        lunchEnd = try container.decodeIfPresent(String.self, forKey: .lunchEnd) ?? "13:30"
        snoozeMinutes = try container.decodeIfPresent(Int.self, forKey: .snoozeMinutes) ?? 10
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        isPaused = try container.decodeIfPresent(Bool.self, forKey: .isPaused) ?? false
        themeID = try container.decodeIfPresent(String.self, forKey: .themeID) ?? "sunrise"
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
    }
}
