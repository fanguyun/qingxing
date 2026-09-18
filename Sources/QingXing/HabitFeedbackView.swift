import SwiftUI

struct HabitFeedbackView: View {
    @ObservedObject var model: AppModel
    @State private var showClearConfirmation = false

    private var theme: AppTheme { model.activeTheme }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            summaryRow
            legendRow

            if hasActivity {
                trendChart
            } else {
                emptyState
            }

            Button(role: .destructive) {
                showClearConfirmation = true
            } label: {
                Label("清除统计", systemImage: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
        .alert("清除统计？", isPresented: $showClearConfirmation) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) {
                model.clearReminderHistory()
            }
        } message: {
            Text("将删除所有历史完成与跳过记录，无法恢复。")
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 10) {
            HabitStatCard(
                value: "\(model.currentCompletedStreak)",
                label: "连续天数",
                color: theme.accent
            )
            HabitStatCard(
                value: weeklyRateText,
                label: "周完成率",
                color: .green
            )
            HabitStatCard(
                value: "\(model.weeklyCompletedCount)/\(model.weeklySkippedCount)",
                label: "完成/跳过",
                color: .orange
            )
        }
    }

    private var legendRow: some View {
        HStack(spacing: 12) {
            legendItem(color: theme.accent, label: "已完成")
            legendItem(color: .orange.opacity(0.65), label: "已跳过")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.secondary)
            Text("暂无记录")
                .font(.system(size: 13, weight: .semibold))
            Text("完成一次提醒后，这里会开始生成本周趋势")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cardCornerRadius, style: .continuous)
                .fill(Color.primary.opacity(0.03))
        )
    }

    private var trendChart: some View {
        let stats = model.recentSevenDayStats
        let maxValue = max(1, stats.map { $0.completed + $0.skipped }.max() ?? 1)

        return HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                VStack(spacing: 6) {
                    Text("\(stat.completed + stat.skipped)")
                        .font(.system(size: 9, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(stat.completed + stat.skipped > 0 ? Color.secondary : Color.clear)
                        .frame(height: 12)

                    HStack(alignment: .bottom, spacing: 2) {
                        bar(for: stat.completed, maxValue: maxValue, color: theme.accent)
                        bar(for: stat.skipped, maxValue: maxValue, color: .orange.opacity(0.65))
                    }
                    .frame(height: 72, alignment: .bottom)

                    Text(Self.weekdayLabel(from: stat.date))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .help("\(Self.weekdayLabel(from: stat.date)) · 完成 \(stat.completed) · 跳过 \(stat.skipped)")
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(Self.weekdayLabel(from: stat.date)) 完成 \(stat.completed) 跳过 \(stat.skipped)")
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.weeklyCompletedCount)
        .animation(.easeInOut(duration: 0.25), value: model.weeklySkippedCount)
    }

    private var hasActivity: Bool {
        model.weeklyCompletedCount + model.weeklySkippedCount > 0
    }

    @ViewBuilder
    private func bar(for value: Int, maxValue: Int, color: Color) -> some View {
        if value == 0 {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.primary.opacity(0.08))
                .frame(width: 10, height: 4)
        } else {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 10, height: barHeight(value, maxValue: maxValue))
        }
    }

    private func barHeight(_ value: Int, maxValue: Int) -> CGFloat {
        let ratio = CGFloat(value) / CGFloat(maxValue)
        return max(6, 64 * ratio)
    }

    private var weeklyRateText: String {
        guard let rate = model.weeklyCompletionRate else { return "--" }
        return "\(Int((rate * 100).rounded()))%"
    }

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private static func weekdayLabel(from date: Date) -> String {
        weekdayFormatter.string(from: date)
    }
}

private struct HabitStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cardCornerRadius, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}
