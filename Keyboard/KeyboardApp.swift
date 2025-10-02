import InputMethodKit

class KeyboardApp: NSApplication {
    let appDelegate = AppDelegate()

    override init() {
        super.init()
        self.delegate = self.appDelegate
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var server = IMKServer()

    func applicationDidFinishLaunching(_ notification: Notification) {

        let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String
        let bundleIdentifier = Bundle.main.bundleIdentifier

        self.server = IMKServer(
            name: connectionName,
            bundleIdentifier: bundleIdentifier
        )
    }
}
