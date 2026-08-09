import Capacitor
import AVFoundation

@objc(TonePlayerPlugin)
public class TonePlayerPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "TonePlayerPlugin"
    public let jsName = "TonePlayer"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "playTone", returnType: CAPPluginReturnPromise)
    ]

    private var keepAlivePlayer: AVAudioPlayer?

    public override func load() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    @objc func playTone(_ call: CAPPluginCall) {
        guard let name = call.getString("name") else {
            call.reject("missing name")
            return
        }

        if name == "stop" {
            keepAlivePlayer?.stop()
            keepAlivePlayer = nil
            call.resolve()
            return
        }

        if name == "keepalive" {
            keepAlivePlayer?.stop()
            if let url = Bundle.main.url(forResource: "silence", withExtension: "wav") {
                if let player = try? AVAudioPlayer(contentsOf: url) {
                    player.numberOfLoops = -1
                    player.volume = 1.0
                    player.play()
                    keepAlivePlayer = player
                }
            }
            call.resolve()
            return
        }

        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            call.reject("tone not found: \(name)")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1.0
            player.play()
        } catch {
            call.reject("playback failed")
            return
        }
        call.resolve()
    }
}
