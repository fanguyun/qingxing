import Foundation
import AppKit
import SwiftUI
import ServiceManagement
import UserNotifications
import QingXingCore

struct DailyReminderStat {
    let date: Date
    let completed: Int
    let skipped: Int
}

final class AppModel: ObservableObject {
    @Published private(set) var settings: AppSettings {
        didSet {
            store.save(settings)
            notificationManager.reschedule(settings: settings)
            inAppScheduler.reschedule(settings: settings)
        }
    }

    let store = SettingsStore()
    let historyStore = ReminderHistoryStore()
    let notificationManager = NotificationManager()
    let inAppScheduler = InAppReminderScheduler()
    let onboardingPresenter = OnboardingPresenter()

    @Published private(set) var reminderHistory: ReminderHistory {
        didSet {
            historyStore.save(reminderHistory)
        }
    }

    @Published private(set) var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var launchAtLoginWarning: String?

    init() {
        var loadedSettings = store.load()
        if store.hasStoredSettings() {
            loadedSettings.hasCompletedOnboarding = true
        }
        settings = loadedSettings
        reminderHistory = historyStore.load()

        notificationManager.onSnooze = { [weak self] in
            Task { @MainActor in
                self?.snooze()
            }
        }
        notificationManager.onComplete = { [weak self] in
            Task { @MainActor in
                self?.recordCompletedReminder()
            }
        }
        notificationManager.onSkip = { [weak self] in
            Task { @MainActor in
                self?.recordSkippedReminder()
            }
        }
        inAppScheduler.configure(
            onSnooze: { [weak self] in
                self?.snooze()
            },
            onComplete: { [weak self] in
                self?.recordCompletedReminder()
            },
            onSkip: { [weak self] in
                self?.recordSkippedReminder()
            }
        )

        Task { await refreshNotificationAuthorizationStatus() }
        notificationManager.reschedule(settings: settings)
        inAppScheduler.reschedule(settings: settings)
        observeSystemEvents()

        if !settings.hasCompletedOnboarding {
            DispatchQueue.main.async { [weak self] in
                self?.showOnboarding()
            }
        }
    }

    var isPaused: Bool { settings.isPaused }

    var activeTheme: AppTheme {
        AppTheme(rawValue: settings.themeID) ?? .sunrise
    }

    var menuBarSymbol: String {
        if isPaused { return "pause.circle.fill" }
        if isInLunchNow { return "cup.and.saucer.fill" }
        return "figure.cooldown"
    }

    var menuBarTint: Color {
        if isPaused { return .secondary }
        if isInLunchNow { return activeTheme.accentSoft }
        return activeTheme.accent
    }

    var todayCompletedReminderCount: Int {
        reminderHistory.day(for: historyStore.dayKey()).completed
    }

    var todaySkippedReminderCount: Int {
        reminderHistory.day(for: historyStore.dayKey()).skipped
    }

    var totalReminderCount: Int {
        reminderDates.count
    }

    var recentSevenDayStats: [DailyReminderStat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset - 6, to: today) ?? today
            let day = reminderHistory.day(for: historyStore.dayKey(for: date))
            return DailyReminderStat(date: date, completed: day.completed, skipped: day.skipped)
        }
    }

    var currentCompletedStreak: Int {
        let calendar = Calendar.current
        var cursor = calendar.startOfDay(for: Date())
        if reminderHistory.day(for: historyStore.dayKey(for: cursor)).completed == 0 {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }

        var streak = 0
        while reminderHistory.day(for: historyStore.dayKey(for: cursor)).completed > 0 {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    var weeklyCompletedCount: Int {
        recentSevenDayStats.reduce(0) { $0 + $1.completed }
    }

    var weeklySkippedCount: Int {
        recentSevenDayStats.reduce(0) { $0 + $1.skipped }
    }

    var weeklyCompletionRate: Double? {
        let total = weeklyCompletedCount + weeklySkippedCount
        guard total > 0 else { return nil }
        return Double(weeklyCompletedCount) / Double(total)
    }

    var nextReminderDate: Date? {
        guard !settings.isPaused else { return nil }
        return ReminderPlanner.nextFireTime(now: Date(), settings: settings, calendar: .current)
    }

    var previousReminderDate: Date? {
        let times = ReminderPlanner.fireTimes(on: Date(), settings: settings, calendar: .current)
        return times.last { $0 <= Date() }
    }

    var isInLunchNow: Bool {
        guard settings.lunchEnabled,
              let start = TimeParser.minutes(from: settings.lunchStart),
              let end = TimeParser.minutes(from: settings.lunchEnd),
              start < end else { return false }
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let now = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        return start <= now && now < end
    }

    var isAfterActivePeriod: Bool {
        guard let start = TimeParser.minutes(from: settings.activeStart),
              let end = TimeParser.minutes(from: settings.activeEnd),
              start < end else { return false }
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let now = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        return now >= end
    }

    var todayActiveEndDate: Date? {
        guard let start = TimeParser.minutes(from: settings.activeStart),
              let end = TimeParser.minutes(from: settings.activeEnd),
              start < end else { return nil }
        let calendar = Calendar.current
        let day = calendar.dateComponents([.year, .month, .day], from: Date())
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = end / 60
        components.minute = end % 60
        return calendar.date(from: components)
    }

    func update(_ mutate: (inout AppSettings) -> Void) {
        var value = settings
        mutate(&value)
        settings = value
    }

    func togglePause() {
        settings.isPaused.toggle()
    }

    func testReminder() {
        inAppScheduler.showTestReminder()
    }

    func snooze() {
        let minutes = settings.snoozeMinutes
        notificationManager.snooze(minutes: minutes)
        inAppScheduler.snooze(minutes: minutes)
    }

    func recordCompletedReminder() {
        var history = reminderHistory
        history.recordCompleted(on: historyStore.dayKey())
        reminderHistory = history
    }

    func recordSkippedReminder() {
        var history = reminderHistory
        history.recordSkipped(on: historyStore.dayKey())
        reminderHistory = history
    }

    func clearReminderHistory() {
        reminderHistory = ReminderHistory()
    }

    func refreshNotificationAuthorizationStatus() async {
        let status = await notificationManager.currentAuthorizationStatus()
        await MainActor.run {
            self.notificationAuthorizationStatus = status
        }
    }

    func requestNotificationPermission() async {
        await notificationManager.requestAuthorization()
        await refreshNotificationAuthorizationStatus()
    }

    func openSystemNotificationSettings() {
        notificationManager.openSystemNotificationSettings()
    }

    var notificationPermissionLabel: String {
        switch notificationAuthorizationStatus {
        case .notDetermined: return "尚未选择"
        case .denied: return "未开启"
        case .authorized, .provisional: return "已开启"
        @unknown default: return "状态未知"
        }
    }

    var notificationPermissionColor: Color {
        switch notificationAuthorizationStatus {
        case .notDetermined: return .secondary
        case .denied: return .orange
        case .authorized, .provisional: return .green
        @unknown default: return .secondary
        }
    }

    var isNotificationPermissionDenied: Bool {
        notificationAuthorizationStatus == .denied
    }

    var isNotificationPermissionNotDetermined: Bool {
        notificationAuthorizationStatus == .notDetermined
    }

    func showOnboarding() {
        onboardingPresenter.show(model: self) { [weak self] in
            self?.update { $0.hasCompletedOnboarding = true }
        }
    }

    func showSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.title == "轻醒设置" {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            return
        }
    }

    private var reminderDates: [Date] {
        ReminderPlanner.fireTimes(on: Date(), settings: settings, calendar: .current)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginWarning = nil
            update { $0.launchAtLogin = enabled }
        } catch {
            launchAtLoginWarning = "无法修改登录项，请在系统设置中检查“登录项”权限。"
            update { $0.launchAtLogin = false }
        }
    }

    private func observeSystemEvents() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.notificationManager.reschedule(settings: self.settings)
            self.inAppScheduler.reschedule(settings: self.settings)
        }

        NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.notificationManager.reschedule(settings: self.settings)
            self.inAppScheduler.reschedule(settings: self.settings)
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { await self.refreshNotificationAuthorizationStatus() }
        }
    }
}
