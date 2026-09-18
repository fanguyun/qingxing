import SwiftUI

/// 倒计时圆环：表示距离下一次提醒的剩余时间占比。
struct CountdownRing: View {
    let nextDate: Date
    let previousDate: Date?
    let intervalSeconds: TimeInterval
    let now: Date
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.10))

            Circle()
                .stroke(accent.opacity(0.30), lineWidth: 6)

            Circle()
                .trim(from: 0, to: visibleFraction)
                .stroke(
                    accent,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Image(systemName: "hourglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accent)
        }
        .frame(width: 40, height: 40)
    }

    private var visibleFraction: CGFloat {
        let value = remainingFraction
        return value <= 0 ? 0 : max(0.03, value)
    }

    private var remainingFraction: CGFloat {
        let remaining = max(0, nextDate.timeIntervalSince(now))
        let total = totalSpan
        guard total > 0 else { return 0 }
        return CGFloat(min(1, max(0, remaining / total)))
    }

    private var totalSpan: TimeInterval {
        if let previousDate, previousDate < nextDate {
            return nextDate.timeIntervalSince(previousDate)
        }
        return max(60, intervalSeconds)
    }
}
