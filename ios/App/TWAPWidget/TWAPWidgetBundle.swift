import WidgetKit
import SwiftUI
import ActivityKit

@main
struct TWAPWidgetBundle: WidgetBundle {
    var body: some Widget {
        TWAPActivityWidget()
    }
}

struct TWAPActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TWAPActivityAttributes.self) { context in
            TWAPLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    TWAPStatusBadge(state: context.state.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TWAPTimeLeft(timeLeft: context.state.timeLeft)
                }
                DynamicIslandExpandedRegion(.center) {
                    TWAPCushionView(cushion: context.state.cushion)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        TWAPSideBadge(side: context.state.side)
                        Spacer()
                        TWAPFlipButton(state: context.state)
                    }
                }
            } compactLeading: {
                TWAPStatusText(state: context.state.state)
            } compactTrailing: {
                TWAPSideBadge(side: context.state.side)
            } minimal: {
                TWAPStatusDot(state: context.state.state)
            }
        }
    }
}

// Flips OVER/UNDER from the island: updates the activity content instantly,
// writes the desired side to the shared App Group defaults, and wakes the app
// (which is kept alive in the background) via a Darwin notification so the
// dashboard JS can persist + echo the change.
func flipSide(_ state: TWAPActivityAttributes.ContentState) {
    let newSide = state.side == "UNDER" ? "OVER" : "UNDER"
    UserDefaults(suiteName: TWAPAppGroup)?.set(newSide, forKey: TWAPSideKey)
    if let activity = Activity<TWAPActivityAttributes>.activities.first {
        var newState = state
        newState.side = newSide
        Task {
            await activity.update(ActivityContent(state: newState, staleDate: nil, relevanceDate: nil))
        }
    }
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(TWAPToggleNotification as CFString),
            nil,
            nil,
            true
        )
}

struct TWAPFlipButton: View {
    let state: TWAPActivityAttributes.ContentState

    var body: some View {
        Button {
            flipSide(state)
        } label: {
            Text("Flip to \(state.side == "UNDER" ? "OVER" : "UNDER")")
                .font(.caption.bold())
        }
        .buttonStyle(.borderedProminent)
    }
}

struct TWAPLockScreenView: View {
    let context: ActivityViewContext<TWAPActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TWAPStatusBadge(state: context.state.state)
                Spacer()
                TWAPSideBadge(side: context.state.side)
            }
            HStack {
                TWAPCushionView(cushion: context.state.cushion)
                Spacer()
                TWAPTimeLeft(timeLeft: context.state.timeLeft)
            }
            TWAPFlipButton(state: context.state)
        }
        .padding()
    }
}

struct TWAPStatusBadge: View {
    let state: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(color)
    }

    var title: String {
        switch state {
        case "EXIT": return "HARD EXIT"
        case "WARN": return "WARNING"
        default: return "SAFE"
        }
    }

    var color: Color {
        switch state {
        case "EXIT": return .red
        case "WARN": return .orange
        default: return .green
        }
    }
}

struct TWAPStatusText: View {
    let state: String

    var body: some View {
        Text(state == "EXIT" ? "EXIT" : state)
            .font(.caption2)
            .foregroundColor(TWAPStatusBadge(state: state).color)
    }
}

struct TWAPCushionView: View {
    let cushion: Double

    var body: some View {
        Text("Cushion $\(String(format: "%.2f", cushion))")
            .font(.headline)
            .foregroundColor(cushion >= 0 ? .green : .red)
    }
}

struct TWAPSideBadge: View {
    let side: String

    var body: some View {
        Text(side == "UNDER" ? "UNDER" : "OVER")
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.gray.opacity(0.25)))
    }
}

struct TWAPTimeLeft: View {
    let timeLeft: Int

    var body: some View {
        Text(timeString)
            .font(.system(.body, design: .monospaced).bold())
            .foregroundColor(.white)
    }

    var timeString: String {
        let s = max(0, timeLeft)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}

struct TWAPStatusDot: View {
    let state: String

    var body: some View {
        Circle()
            .fill(TWAPStatusBadge(state: state).color)
            .frame(width: 8, height: 8)
    }
}
