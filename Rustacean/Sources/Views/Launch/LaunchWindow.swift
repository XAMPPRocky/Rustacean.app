import Cocoa

class LaunchWindow: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.window?.titlebarAppearsTransparent = true
        self.window?.title = ""
    }

}
