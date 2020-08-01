import Cocoa

class LaunchController: NSViewController {

    @IBOutlet weak var subtitle: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        subtitle.stringValue = "Latest Stable Version (\(Rustc.version(.stable) ?? "???"))"
    }
    
}
