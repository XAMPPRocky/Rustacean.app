import Cocoa
import Toml

let LAUNCHER_APP_ID = "xampprocky.LaunchRustacean.app"

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static var installWindow: NSWindowController? = nil
    var menu: TaskBar? = nil

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        #if !DEBUG
            AppMover.moveIfNecessary()
        #endif

        // Terminate any existing launcher processes.
        if NSWorkspace.shared.runningApplications.filter({ $0.bundleIdentifier == LAUNCHER_APP_ID }).isEmpty {
            DistributedNotificationCenter.default().post(name: .killLauncher, object: Bundle.main.bundleIdentifier!)
        }

        if Rustup.isPresent() {
            DispatchQueue.main.async {
                self.menu = TaskBar()
            }
        } else {
            if let window = AppDelegate.installWindow {
                window.showWindow(self)
                return
            }

            NSApp.activate(ignoringOtherApps: true)
            let storyboard = NSStoryboard(name: "Installation", bundle: nil)
            let controller = (storyboard.instantiateController(withIdentifier: "InstallWindow") as! NSWindowController)
            controller.window?.title = "Rust.app"
            controller.window?.center()
            controller.window?.collectionBehavior = .moveToActiveSpace
            controller.window?.makeKeyAndOrderFront(nil)
            controller.window?.orderFrontRegardless()

            AppDelegate.installWindow = controller
            AppDelegate.installWindow!.showWindow(self)
        }

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

