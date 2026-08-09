import ActivityKit

struct TWAPActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var state: String      // SAFE / WARN / EXIT
        var side: String       // OVER / UNDER
        var cushion: Double
        var timeLeft: Int
    }
}

let TWAPAppGroup = "group.com.benidoe.btctwap.shared"
let TWAPSideKey = "twapDesiredSide"
let TWAPToggleNotification = "com.benidoe.btctwap.toggleSide"
