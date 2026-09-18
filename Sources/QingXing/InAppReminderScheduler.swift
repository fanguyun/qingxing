import Foundation
import AppKit
import SwiftUI
import QingXingCore

/// 负责在提醒时刻弹出一个始终置顶、带有动效的悬浮卡片。
final class InAppReminderScheduler {
    private let presenter = ReminderAlertPresenter()
    private var timer: Timer?
    private var storedSettings: AppSettings?
    private var storedTheme: AppTheme = .sunrise
    private var onSnooze: (() -> Void)?
    private var onComplete: (() -> Void)?
    private var onSkip: (() -> Void)?

    func configure(
        onSnooze: @escaping () -> Void,
        onComplete: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.onSnooze = onSnooze
        self.onComplete = onComplete
        self.onSkip = onSkip

        presenter.onSnooze = { [weak self] in
            self?.onSnooze?()
        }
        presenter.onComplete = { [weak self] in
            self?.finishRegularReminder(self?.onComplete)
        }
        presenter.onSkip = { [weak self] in
            self?.finishRegularReminder(self?.onSkip)
        }
    }

    func reschedule(settings: AppSettings) {
        storedSettings = settings
        storedTheme = AppTheme(rawValue: settings.themeID) ?? .sunrise
        timer?.invalidate()
        timer = nil

        guard !settings.isPaused else {
            presenter.hide()
            return
        }

        scheduleNextRegular(after: Date())
    }

    func snooze(minutes: Int) {
        presenter.hide()
        scheduleTimer(at: Date().addingTimeInterval(TimeInterval(max(1, minutes) * 60)))
    }

    func showTestReminder() {
        presenter.show(theme: storedTheme, isTest: true)
    }

    private func finishRegularReminder(_ action: (() -> Void)?) {
        action?()
        presenter.hide()
        scheduleNextRegular(after: Date())
    }

    private func scheduleNextRegular(after now: Date) {
        guard let settings = storedSettings, !settings.isPaused else { return }
        guard let next = ReminderPlanner.nextFireTime(now: now, settings: settings, calendar: .current) else { return }
        scheduleTimer(at: next)
    }

    private func scheduleTimer(at date: Date) {
        timer?.invalidate()

        let timer = Timer(fire: date, interval: 0, repeats: false) { [weak self] _ in
            self?.timer = nil
            self?.presenter.show(theme: self?.storedTheme ?? .sunrise)
            self?.scheduleNextRegular(after: Date())
        }

        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}

/// AppKit 悬浮窗口：负责把 SwiftUI 提醒卡片显示到所有应用之上。
final class ReminderAlertPresenter {
    var onSnooze: (() -> Void)?
    var onComplete: (() -> Void)?
    var onSkip: (() -> Void)?

    private var panel: NSPanel?
    private var autoDismissTimer: Timer?
    private var escapeMonitor: Any?

    func show(theme: AppTheme, isTest: Bool = false) {
        hide(animated: false)

        let rootView = ReminderAlertView(
            theme: theme,
            onSnooze: { [weak self] in
                guard let self else { return }
                if isTest { self.hide() } else { self.onSnooze?() }
            },
            onComplete: { [weak self] in
                guard let self else { return }
                if isTest { self.hide() } else { self.onComplete?() }
            },
            onSkip: { [weak self] in
                guard let self else { return }
                if isTest { self.hide() } else { self.onSkip?() }
            }
        )
        let hostingView = NSHostingView(rootView: rootView)
        let size = NSSize(width: 400, height: 210)
        hostingView.frame = NSRect(origin: .zero, size: size)

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.contentView = hostingView

        position(panel: panel, size: size)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            panel.animator().alphaValue = 1
        }

        NSSound(named: NSSound.Name("Glass"))?.play()
        if NSSound(named: NSSound.Name("Glass")) == nil {
            NSSound.beep()
        }

        self.panel = panel
        scheduleAutoDismiss(isTest: isTest)
        installEscapeMonitor()
    }

    func hide() {
        hide(animated: true)
    }

    private func hide(animated: Bool) {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        removeEscapeMonitor()

        guard let panel else { return }
        self.panel = nil

        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                panel.animator().alphaValue = 0
            }, completionHandler: {
                panel.orderOut(nil)
            })
        } else {
            panel.orderOut(nil)
        }
    }

    private func scheduleAutoDismiss(isTest: Bool) {
        autoDismissTimer?.invalidate()
        let interval: TimeInterval = isTest ? 6 : 30
        autoDismissTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }

    private func installEscapeMonitor() {
        removeEscapeMonitor()
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            self?.hide()
            return nil
        }
    }

    private func removeEscapeMonitor() {
        guard let escapeMonitor else { return }
        NSEvent.removeMonitor(escapeMonitor)
        self.escapeMonitor = nil
    }

    private func position(panel: NSPanel, size: NSSize) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let margin: CGFloat = 24
        let x = visible.maxX - size.width - margin
        let y = visible.maxY - size.height - margin
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: false)
    }
}

private struct ReminderAlertView: View {
    let theme: AppTheme
    let onSnooze: () -> Void
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var appeared = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.gradient)
                .frame(width: 380, height: 190)
                .shadow(color: theme.accent.opacity(0.45), radius: 20, y: 8)

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 5)
                        .scaleEffect(pulse ? 1.35 : 0.95)
                        .opacity(pulse ? 0 : 0.9)

                    Circle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 72, height: 72)

                    Image(systemName: "figure.walk")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 88, height: 88)

                VStack(alignment: .leading, spacing: 8) {
                    Text("该起来活动啦")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    Text("已经坐了很久，站起来喝口水、走动几分钟吧。")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        Button("已完成", action: onComplete)
                            .buttonStyle(ReminderAlertButtonStyle(primary: true, accent: theme.accent))

                        Button("稍后提醒", action: onSnooze)
                            .buttonStyle(ReminderAlertButtonStyle(primary: false, accent: theme.accent))

                        Button("跳过", action: onSkip)
                            .buttonStyle(ReminderAlertButtonStyle(primary: false, accent: theme.accent))
                    }
                    .padding(.top, 2)
                }
            }
            .padding(20)
        }
        .frame(width: 400, height: 210)
        .scaleEffect(appeared ? 1 : 0.86)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

private struct ReminderAlertButtonStyle: ButtonStyle {
    let primary: Bool
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(primary ? accent : Color.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(primary ? Color.white : Color.white.opacity(0.16))
            )
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
