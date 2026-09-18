import Foundation
import AppKit
import UserNotifications
import QingXingCore

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let categoryID = "SEDENTARY_REMINDER"
    static let snoozeActionID = "SNOOZE_ACTION"
    static let dismissActionID = "DISMISS_ACTION"
    static let completeActionID = "COMPLETE_ACTION"
    static let skipActionID = "SKIP_ACTION"

    var onSnooze: (() -> Void)?
    var onComplete: (() -> Void)?
    var onSkip: (() -> Void)?

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
        registerCategory()
    }

    private func registerCategory() {
        let snooze = UNNotificationAction(
            identifier: Self.snoozeActionID,
            title: "稍后提醒",
            options: []
        )
        let dismiss = UNNotificationAction(
            identifier: Self.dismissActionID,
            title: "知道了",
            options: []
        )
        let complete = UNNotificationAction(
            identifier: Self.completeActionID,
            title: "已完成",
            options: []
        )
        let skip = UNNotificationAction(
            identifier: Self.skipActionID,
            title: "跳过",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryID,
            actions: [complete, snooze, skip, dismiss],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func openSystemNotificationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") else { return }
        NSWorkspace.shared.open(url)
    }

    func reschedule(settings: AppSettings, now: Date = Date(), calendar: Calendar = .current) {
        guard !settings.isPaused else {
            cancelReminders()
            return
        }

        let upcoming = ReminderPlanner.fireTimes(on: now, settings: settings, calendar: calendar)
            .filter { $0 > now }

        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            let stale = requests
                .filter { $0.identifier.hasPrefix("reminder.") }
                .map { $0.identifier }
            self.center.removePendingNotificationRequests(withIdentifiers: stale)

            for (index, date) in upcoming.enumerated() {
                let components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: date
                )
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: false
                )
                let content = Self.reminderContent()
                let identifier = "reminder.\(index).\(date.timeIntervalSince1970)"
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )
                self.center.add(request)
            }
        }
    }

    func cancelReminders() {
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            let stale = requests
                .filter { $0.identifier.hasPrefix("reminder.") }
                .map { $0.identifier }
            self.center.removePendingNotificationRequests(withIdentifiers: stale)
        }
    }

    func snooze(minutes: Int, now: Date = Date()) {
        let content = Self.reminderContent()
        content.title = "久坐提醒（稍后）"
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(max(1, minutes) * 60),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "snooze.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    private static func reminderContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "久坐提醒"
        content.body = "起身活动一下吧，喝口水、走动几分钟。"
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = categoryID
        return content
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == Self.snoozeActionID {
            onSnooze?()
        } else if response.actionIdentifier == Self.completeActionID {
            onComplete?()
        } else if response.actionIdentifier == Self.skipActionID {
            onSkip?()
        }
        completionHandler()
    }
}
