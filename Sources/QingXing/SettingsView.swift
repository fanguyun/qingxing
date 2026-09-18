import SwiftUI
import AppKit
import Luminare
import QingXingCore

enum SettingsTab: String, CaseIterable, Identifiable {
    case reminders = "提醒设置"
    case statistics = "统计"

    var id: String { rawValue }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var selectedTab: SettingsTab = .reminders

    private var theme: AppTheme { model.activeTheme }

    var body: some View {
        LuminareView {
            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, 21)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .overlay(alignment: .bottom) {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                    .shadow(color: Color.black.opacity(0.06), radius: 3, y: 2)

                tabPicker
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        ScrollViewScrollerStyle()
                            .frame(width: 0, height: 0)

                        LuminareSectionStack {
                        if selectedTab == .reminders {
                        LuminareSection("提醒时段", "每天仅在此时间段内提醒") {
                            LuminareCompose("开始时间") {
                                TimeStepper(time: timeBinding(\.activeStart))
                            }
                            LuminareCompose("结束时间") {
                                TimeStepper(time: timeBinding(\.activeEnd))
                            }

                            if let warning = reminderTimeWarning {
                                SettingsWarningText(warning)
                            }
                        }

                        LuminareSection("提醒间隔", "从开始时间起，按固定间隔步进") {
                            HStack(spacing: 12) {
                                Slider(value: intervalSliderBinding, in: 5...180, step: 5)
                                Text("\(model.settings.intervalMinutes) 分钟")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                    .frame(width: 56, alignment: .trailing)
                            }
                        }

                        LuminareSection("自定义时间点") {
                            if model.settings.customTimes.isEmpty {
                                Text("未添加自定义时间点")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(model.settings.customTimes.indices, id: \.self) { index in
                                    HStack {
                                        Text("时间点 \(index + 1)")
                                        Spacer()
                                        TimeStepper(time: customTimeBinding(index))
                                        Button {
                                            model.update { $0.customTimes.remove(at: index) }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.borderless)
                                        .help("删除此时间点")
                                    }
                                }
                            }
                            LuminareButton("添加时间点", label: {
                                Image(systemName: "plus")
                            }, action: {
                                addTimePoint()
                            })
                        }

                        LuminareSection("午休免打扰") {
                            LuminareToggle("启用午休免打扰", isOn: lunchEnabledBinding)
                            if model.settings.lunchEnabled {
                                LuminareCompose("午休开始") {
                                    TimeStepper(time: timeBinding(\.lunchStart))
                                }
                                LuminareCompose("午休结束") {
                                    TimeStepper(time: timeBinding(\.lunchEnd))
                                }

                                if let warning = lunchTimeWarning {
                                    SettingsWarningText(warning)
                                }
                            }
                        }

                        LuminareSection("稍后提醒", "点击通知中的「稍后提醒」后延迟的时间") {
                            HStack(spacing: 12) {
                                Slider(value: snoozeSliderBinding, in: 1...60, step: 1)
                                Text("\(model.settings.snoozeMinutes) 分钟")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                    .frame(width: 56, alignment: .trailing)
                            }
                        }

                        LuminareSection("其他") {
                            LuminareToggle("登录时自动启动", isOn: launchAtLoginBinding)
                            if let warning = model.launchAtLoginWarning {
                                SettingsWarningText(warning)
                            }
                            LuminareCompose("通知权限") {
                                HStack(spacing: 8) {
                                    Text(model.notificationPermissionLabel)
                                        .font(.system(size: 13))
                                        .foregroundStyle(model.notificationPermissionColor)
                                    Spacer()
                                    if model.isNotificationPermissionDenied {
                                        Button("打开系统设置") {
                                            model.openSystemNotificationSettings()
                                        }
                                        .buttonStyle(.link)
                                    } else if model.isNotificationPermissionNotDetermined {
                                        Button("允许通知") {
                                            Task { await model.requestNotificationPermission() }
                                        }
                                        .buttonStyle(.link)
                                    }
                                }
                            }
                            LuminareButton("立即测试提醒", label: {
                                Image(systemName: "bell.badge.fill")
                            }, action: {
                                model.testReminder()
                            })
                            LuminareButton("查看欢迎引导", label: {
                                Image(systemName: "sparkles")
                            }, action: {
                                model.showOnboarding()
                            })
                        }

                        LuminareSection("配色方案", "切换圆环、图标和提醒卡片的主色") {
                            ThemePreviewCard(theme: theme)

                            LuminarePickerMenu(
                                "配色",
                                selection: themeBinding,
                                items: AppTheme.allCases.map(\.rawValue)
                            ) { id in
                                let theme = AppTheme(rawValue: id) ?? .sunrise
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(theme.gradient)
                                        .frame(width: 12, height: 12)
                                    Text(theme.displayName)
                                }
                            }
                        }
                        } else {
                        LuminareSection("今日统计", "你今天对提醒的完成情况") {
                            HStack(spacing: 12) {
                                StatItem(
                                    value: "\(model.todayCompletedReminderCount)",
                                    label: "已完成",
                                    color: theme.accent
                                )
                                StatItem(
                                    value: "\(model.todaySkippedReminderCount)",
                                    label: "已跳过",
                                    color: .orange
                                )
                                StatItem(
                                    value: "\(model.totalReminderCount)",
                                    label: "今日计划",
                                    color: .secondary
                                )
                            }
                            .padding(.vertical, 2)
                        }

                        LuminareSection("习惯趋势", "最近 7 天的坚持情况") {
                            HabitFeedbackView(model: model)
                        }
                        }
                        }
                        .animation(.easeInOut(duration: 0.2), value: selectedTab)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .frame(minWidth: 560, idealWidth: 560, minHeight: 620, idealHeight: 700)
        .luminareTint(overridingWith: theme.accent)
    }

    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.gradient)
                Image(systemName: "figure.cooldown")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text("轻醒")
                    .font(.title2.weight(.semibold))
                Text("轻健康 · 久坐提醒")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var tabPicker: some View {
        Picker("页面", selection: $selectedTab) {
            ForEach(SettingsTab.allCases) { tab in
                Text(tab.rawValue)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityLabel("设置页面")
    }
}

private struct ScrollViewScrollerStyle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            var candidate: NSView? = nsView.superview
            while let view = candidate {
                if let scrollView = view as? NSScrollView {
                    scrollView.scrollerStyle = .overlay
                    scrollView.autohidesScrollers = true
                    scrollView.verticalScroller?.controlSize = .mini
                    break
                }
                candidate = view.superview
            }
        }
    }
}

private struct StatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}

private struct ThemePreviewCard: View {
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(0.12))
                Circle()
                    .stroke(theme.accent.opacity(0.32), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: 0.62)
                    .stroke(
                        theme.accent,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Image(systemName: "figure.cooldown")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(theme.displayName)
                    .font(.system(size: 13, weight: .semibold))
                Text("圆环、状态与提醒卡片实时预览")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cardCornerRadius, style: .continuous)
                .fill(theme.gradient.opacity(0.16))
        )
    }
}

private struct SettingsWarningText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(text)
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.orange)
        .padding(.horizontal, 4)
    }
}

private struct TimeStepper: View {
    @Binding var time: String
    var step: Int = 5

    @State private var text: String
    @State private var showInvalidHint = false
    @FocusState private var isFocused: Bool

    init(time: Binding<String>, step: Int = 5) {
        self._time = time
        self.step = step
        self._text = State(initialValue: Self.formatted(time.wrappedValue))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Button {
                    adjust(by: -step)
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(TimeStepperButtonStyle())

                TextField("HH:mm", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .frame(width: 54)
                    .focused($isFocused)
                    .onSubmit(commit)
                    .onChange(of: isFocused) { _, focused in
                        if !focused { commit() }
                    }
                    .onKeyPress(.upArrow) {
                        adjust(by: step)
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        adjust(by: -step)
                        return .handled
                    }

                Button {
                    adjust(by: step)
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(TimeStepperButtonStyle())
            }

            if showInvalidHint {
                Text("请输入 00:00–23:59")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onChange(of: time) { _, newValue in
            guard !isFocused else { return }
            text = Self.formatted(newValue)
        }
        .onChange(of: text) { _, newValue in
            guard let minutes = TimeParser.minutes(from: newValue) else {
                showInvalidHint = !newValue.isEmpty
                return
            }
            showInvalidHint = false
            let formatted = TimeParser.string(fromMinutes: minutes)
            if time != formatted {
                time = formatted
            }
            if text != formatted {
                text = formatted
            }
        }
    }

    private func adjust(by delta: Int) {
        guard let current = TimeParser.minutes(from: text) else {
            text = Self.formatted(time)
            showInvalidHint = true
            return
        }

        showInvalidHint = false
        let clamped = max(0, min(23 * 60 + 59, current + delta))
        let newValue = TimeParser.string(fromMinutes: clamped)
        time = newValue
        text = newValue
    }

    private func commit() {
        guard let minutes = TimeParser.minutes(from: text) else {
            text = Self.formatted(time)
            showInvalidHint = true
            return
        }

        showInvalidHint = false
        let newValue = TimeParser.string(fromMinutes: minutes)
        time = newValue
        text = newValue
    }

    private static func formatted(_ value: String) -> String {
        guard let minutes = TimeParser.minutes(from: value) else { return "09:00" }
        return TimeParser.string(fromMinutes: minutes)
    }
}

private struct TimeStepperButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: 24, height: 22)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.12 : 0.06))
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}

private extension SettingsView {
    var intervalSliderBinding: Binding<Double> {
        Binding(
            get: { Double(model.settings.intervalMinutes) },
            set: { newValue in model.update { $0.intervalMinutes = Int(newValue.rounded()) } }
        )
    }

    var snoozeSliderBinding: Binding<Double> {
        Binding(
            get: { Double(model.settings.snoozeMinutes) },
            set: { newValue in model.update { $0.snoozeMinutes = Int(newValue.rounded()) } }
        )
    }

    var lunchEnabledBinding: Binding<Bool> {
        Binding(
            get: { model.settings.lunchEnabled },
            set: { newValue in model.update { $0.lunchEnabled = newValue } }
        )
    }

    var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { model.settings.launchAtLogin },
            set: { newValue in model.setLaunchAtLogin(newValue) }
        )
    }

    var themeBinding: Binding<String> {
        Binding(
            get: { model.settings.themeID },
            set: { newValue in
                model.update { $0.themeID = newValue }
            }
        )
    }

    var reminderTimeWarning: String? {
        guard let start = TimeParser.minutes(from: model.settings.activeStart),
              let end = TimeParser.minutes(from: model.settings.activeEnd) else {
            return "请输入有效的时间格式 HH:mm"
        }
        guard start < end else { return "开始时间必须早于结束时间" }
        return nil
    }

    var lunchTimeWarning: String? {
        guard model.settings.lunchEnabled else { return nil }
        guard let start = TimeParser.minutes(from: model.settings.lunchStart),
              let end = TimeParser.minutes(from: model.settings.lunchEnd) else {
            return "请输入有效的时间格式 HH:mm"
        }
        guard start < end else { return "午休开始必须早于结束时间" }

        if let activeStart = TimeParser.minutes(from: model.settings.activeStart),
           let activeEnd = TimeParser.minutes(from: model.settings.activeEnd),
           activeStart < activeEnd {
            let isInside = start >= activeStart && end <= activeEnd
            if !isInside { return "午休时段应位于提醒时段内" }
        }
        return nil
    }

    func addTimePoint() {
        model.update { $0.customTimes.append("10:00") }
    }

    func timeBinding(_ keyPath: WritableKeyPath<AppSettings, String>) -> Binding<String> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { newValue in
                model.update { $0[keyPath: keyPath] = newValue }
            }
        )
    }

    func customTimeBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: {
                guard model.settings.customTimes.indices.contains(index) else {
                    return "09:00"
                }
                return model.settings.customTimes[index]
            },
            set: { newValue in
                model.update {
                    guard $0.customTimes.indices.contains(index) else { return }
                    $0.customTimes[index] = newValue
                }
            }
        )
    }
}
