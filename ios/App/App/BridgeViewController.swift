import Capacitor
import WebKit

class BridgeViewController: CAPBridgeViewController {
    override func viewDidLoad() {
        // Register app-local native plugins before the web content loads so the
        // Capacitor JS bridge exposes them to the dashboard.
        bridge?.registerPluginInstance(TonePlayerPlugin())
        bridge?.registerPluginInstance(TWAPLiveActivityPlugin())

        super.viewDidLoad()

        // iOS 17+: keep the webview processing while the app is backgrounded
        // (needed so JS timers/WebSockets keep running during background audio).
        // Note: a webview playing audio is also exempted from background suspension.
        webView?.configuration.preferences.inactiveSchedulingPolicy = WKPreferences.InactiveSchedulingPolicy.none
    }
}
