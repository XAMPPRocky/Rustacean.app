import Cocoa
import Toml

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static var preferencesWindow: NSWindowController? = nil
    var menu: TaskBar? = nil

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        #if !DEBUG
            AppMover.moveIfNecessary()
        #endif

        if Rustup.isPresent() {
            DispatchQueue.main.async {
                self.menu = TaskBar()
            }
        } else {
            if let window = AppDelegate.preferencesWindow {
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
            
            AppDelegate.preferencesWindow = controller
            AppDelegate.preferencesWindow!.showWindow(self)
        }

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

