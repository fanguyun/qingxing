import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow
    @State private var now = Date()

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var theme: AppTheme { model.activeTheme }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 10)

            countdownCard(now: now)
                .padding(.bottom, 10)

            Divider()

            actionButtons
                .padding(.vertical, 6)

            Divider()

            quitButton
                .padding(.top, 6)
        }
        .padding(12)
        .frame(width: 280, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
        .onReceive(ticker) { date in
            now = date
        }
        .onAppear {
            now = Date()
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(theme.gradient)
                Image(systemName: "figure.cooldown")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 22, height: 22)

            Text("轻醒")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            statusBadge
        }
        .frame(height: 22)
    }

    private var statusBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            Text(statusText)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.primary.opacity(0.06)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(statusText)
    }

    private func countdownCard(now: Date) -> some View {
        ZStack(alignment: .leading) {
            if model.isPaused {
                pausedContent
            } else if let next = model.nextReminderDate {
                countdownContent(nextDate: next, now: now)
            } else if model.isAfterActivePeriod || model.todayActiveEndDate == nil {
                endedContent
            } else {
                lastReminderPassedContent(now: now)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cardCornerRadius, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
    }

    @ViewBuilder
    private func countdownContent(nextDate: Date, now: Date) -> some View {
        HStack(spacing: 12) {
            CountdownRing(
                nextDate: nextDate,
                previousDate: model.previousReminderDate,
                intervalSeconds: TimeInterval(model.settings.intervalMinutes) * 60,
                now: now,
                accent: theme.accent
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(model.isInLunchNow
                     ? "午休中 · 完成 \(model.todayCompletedReminderCount)/\(model.totalReminderCount) · 连续 \(model.currentCompletedStreak) 天"
                     : "下次提醒 · 完成 \(model.todayCompletedReminderCount)/\(model.totalReminderCount) · 连续 \(model.currentCompletedStreak) 天")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(Self.timeString(from: nextDate))
                    .font(.system(size: 17, weight: .semibold))
                    .monospacedDigit()
                Text("剩余 \(Self.countdownString(max(0, nextDate.timeIntervalSince(now))))")
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(theme.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pausedContent: some View {
        HStack(spacing: 12) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(theme.warning)

            VStack(alignment: .leading, spacing: 3) {
                Text("今日不再提醒")
                    .font(.system(size: 13, weight: .semibold))
                Text("恢复后继续提醒")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var endedContent: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(theme.accent)

            VStack(alignment: .leading, spacing: 3) {
                Text("今日提醒已结束")
                    .font(.system(size: 13, weight: .semibold))
                Text("今日完成 \(model.todayCompletedReminderCount) · 跳过 \(model.todaySkippedReminderCount) · 连续 \(model.currentCompletedStreak) 天")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func lastReminderPassedContent(now: Date) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(theme.accent)

            VStack(alignment: .leading, spacing: 3) {
                Text("今日最后提醒已过")
                    .font(.system(size: 13, weight: .semibold))
                if let end = model.todayActiveEndDate {
                    Text("距时段结束 \(Self.countdownString(max(0, end.timeIntervalSince(now))))")
                        .font(.system(size: 11, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(theme.accent)
                } else {
                    Text("明天再提醒你")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionButtons: some View {
        VStack(spacing: 2) {
            MenuActionButton(
                title: model.isPaused ? "恢复提醒" : "暂停提醒",
                icon: model.isPaused ? "play.circle.fill" : "pause.circle.fill",
                accent: .accentColor,
                helpText: model.isPaused ? "恢复今日提醒" : "暂停今日提醒"
            ) {
                model.togglePause()
            }

            MenuActionButton(
                title: "打开设置",
                icon: "gearshape.2.fill",
                accent: .accentColor,
                helpText: "打开设置"
            ) {
                openSettings()
            }
        }
    }

    private var quitButton: some View {
        MenuActionButton(
            title: "退出轻醒",
            icon: "power.circle.fill",
            accent: .secondary,
            isDestructive: true,
            helpText: "退出轻醒"
        ) {
            NSApp.terminate(nil)
        }
    }

    private var statusText: String {
        if model.isPaused { return "已暂停" }
        if model.isInLunchNow { return "午休中" }
        if model.isAfterActivePeriod { return "已结束" }
        return "提醒中"
    }

    private var statusColor: Color {
        if model.isPaused { return theme.warning }
        if model.isInLunchNow { return theme.accentSoft }
        if model.isAfterActivePeriod { return .secondary }
        return .green
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "settings")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            model.showSettingsWindow()
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static func timeString(from date: Date) -> String {
        timeFormatter.string(from: date)
    }

    private static func countdownString(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded()))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}

private struct MenuActionButton: View {
    let title: String
    let icon: String
    let accent: Color
    var isDestructive: Bool = false
    let helpText: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 20)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: UIConstants.controlCornerRadius, style: .continuous)
                    .fill(isHovering ? Color.primary.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(MenuActionButtonStyle())
        .onHover { hovering in
            isHovering = hovering
        }
        .help(helpText)
    }

    private var iconColor: Color {
        guard isDestructive else { return accent }
        return isHovering ? .red : .secondary
    }
}

private struct MenuActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.62 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
