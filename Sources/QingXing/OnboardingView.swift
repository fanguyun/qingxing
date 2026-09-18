import SwiftUI
import AppKit
import UserNotifications

struct OnboardingView: View {
    @ObservedObject var model: AppModel
    let onFinish: () -> Void

    private var theme: AppTheme { model.activeTheme }

    var body: some View {
        VStack(spacing: 20) {
            header

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "figure.cooldown", title: "定时提醒", subtitle: "在设定的工作时段内，按间隔提醒你起身活动")
                featureRow(icon: "bell.badge.fill", title: "醒目提醒", subtitle: "系统通知与置顶卡片同时提醒，不会轻易错过")
                featureRow(icon: "cup.and.saucer.fill", title: "午休免打扰", subtitle: "午休时段自动暂停，不打扰休息")
            }

            permissionRow

            Toggle(isOn: launchAtLoginBinding) {
                Text("登录时自动启动")
                    .font(.system(size: 13, weight: .medium))
            }
            .toggleStyle(.switch)

            if let warning = model.launchAtLoginWarning {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Spacer(minLength: 8)

            Button(action: onFinish) {
                Text("开始使用")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(theme.accent)
        }
        .padding(28)
        .frame(width: 480, height: 520)
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.gradient)
                    .frame(width: 76, height: 76)
                Image(systemName: "figure.cooldown")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("欢迎使用轻醒")
                .font(.title2.weight(.semibold))
            Text("每坐一段时间，提醒你起来活动一下")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.accent)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var permissionRow: some View {
        HStack(spacing: 10) {
            Image(systemName: permissionSymbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(permissionColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("通知权限")
                    .font(.system(size: 13, weight: .semibold))
                Text(permissionText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if model.notificationAuthorizationStatus == .notDetermined {
                Button("允许通知") {
                    Task { await model.requestNotificationPermission() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else if model.notificationAuthorizationStatus == .denied {
                Button("去设置") {
                    model.openSystemNotificationSettings()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cardCornerRadius, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
    }

    private var permissionText: String {
        switch model.notificationAuthorizationStatus {
        case .notDetermined: return "尚未选择，点击开启后才能收到提醒"
        case .denied: return "未开启，提醒可能无法送达"
        case .authorized, .provisional: return "已开启，提醒会正常送达"
        @unknown default: return "状态未知"
        }
    }

    private var permissionSymbol: String {
        switch model.notificationAuthorizationStatus {
        case .notDetermined: return "bell.badge"
        case .denied: return "bell.slash.fill"
        case .authorized, .provisional: return "bell.badge.fill"
        @unknown default: return "bell"
        }
    }

    private var permissionColor: Color {
        switch model.notificationAuthorizationStatus {
        case .notDetermined: return .accentColor
        case .denied: return .orange
        case .authorized, .provisional: return .green
        @unknown default: return .secondary
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { model.settings.launchAtLogin },
            set: { newValue in model.setLaunchAtLogin(newValue) }
        )
    }
}

final class OnboardingPresenter: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private var onFinish: (() -> Void)?
    private var hasFinished = false

    func show(model: AppModel, onFinish: @escaping () -> Void) {
        if let panel {
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        self.onFinish = onFinish
        hasFinished = false

        let rootView = OnboardingView(model: model) { [weak self] in
            self?.finish()
        }
        let hostingView = NSHostingView(rootView: rootView)
        let size = NSSize(width: 480, height: 520)
        hostingView.frame = NSRect(origin: .zero, size: size)

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "欢迎使用轻醒"
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.contentView = hostingView
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.panel = panel
    }

    func windowWillClose(_ notification: Notification) {
        finish()
    }

    private func finish() {
        guard !hasFinished else { return }
        hasFinished = true
        onFinish?()
        onFinish = nil
        let panel = self.panel
        self.panel = nil
        panel?.close()
    }
}
