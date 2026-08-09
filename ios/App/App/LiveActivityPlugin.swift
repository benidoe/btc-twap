import Capacitor
import ActivityKit

@objc(TWAPLiveActivityPlugin)
public class TWAPLiveActivityPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "TWAPLiveActivityPlugin"
    public let jsName = "TWAPLiveActivity"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "update", returnType: CAPPluginReturnPromise)
    ]

    public static var shared: TWAPLiveActivityPlugin?
    private var lastActivity: Activity<TWAPActivityAttributes>?

    private let darwinCallback: @convention(c) (CFNotificationCenter?, UnsafeMutableRawPointer?, CFString?, UnsafeRawPointer?, CFDictionary?) -> Void = { _, observer, _, _, _ in
        guard let observer else { return }
        let plugin = Unmanaged<TWAPLiveActivityPlugin>.fromOpaque(observer).takeUnretainedValue()
        plugin.notifyListeners("twapAction", data: ["action": "toggleSide"])
    }

    public override func load() {
        TWAPLiveActivityPlugin.shared = self
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            observer,
            darwinCallback,
            TWAPToggleNotification as CFString,
            nil,
            .deliverImmediately
        )
    }

    // JS pushes the current dashboard state; native refreshes the island/lock screen.
    @objc func update(_ call: CAPPluginCall) {
        guard let state = call.getString("state"),
              let side = call.getString("side") else {
            call.reject("missing state/side")
            return
        }
        let cushion = call.getDouble("cushion") ?? 0
        let timeLeft = call.getInt("timeLeft") ?? 0

        let contentState = TWAPActivityAttributes.ContentState(
            state: state,
            side: side,
            cushion: cushion,
            timeLeft: timeLeft
        )

        let activity = lastActivity ?? Activity<TWAPActivityAttributes>.activities.first
        guard let activity = activity else {
            call.resolve()
            return
        }
        lastActivity = activity
        Task {
            await activity.update(using: contentState)
            call.resolve()
        }
    }

    // Called by the app delegate when the app enters the background.
    // Starts (or reuses) one Live Activity that lasts long enough to cover
    // many 15-minute windows; the dashboard keeps its content fresh each second.
    public static func start() {
        if let existing = Activity<TWAPActivityAttributes>.activities.first {
            shared?.lastActivity = existing
            return
        }
        let initialState = TWAPActivityAttributes.ContentState(state: "SAFE", side: "OVER", cushion: 0, timeLeft: 900)
        let endDate = Date().addingTimeInterval(3600 * 4)

        do {
            let attributes = TWAPActivityAttributes()
            let content = ActivityContent(state: initialState, staleDate: nil, relevanceDate: nil)
            let activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            shared?.lastActivity = activity
        } catch {
            // Live Activities may be unavailable or disabled; ignore.
        }
    }

    // Called by the app delegate when the app returns to the foreground.
    public static func stop() {
        let activity = shared?.lastActivity ?? Activity<TWAPActivityAttributes>.activities.first
        if let activity = activity {
            Task {
                await activity.end(activity.content.state, dismissalPolicy: .immediate)
            }
        }
        shared?.lastActivity = nil
    }
}
