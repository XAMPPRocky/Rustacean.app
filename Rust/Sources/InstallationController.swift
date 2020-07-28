import Cocoa

class InstallationController: NSViewController {
    @IBOutlet weak var profileButton: NSPopUpButton!
    @IBOutlet weak var environmentCheckbox: NSButton!
    @IBOutlet var installOutput: NSTextView!
    @IBOutlet weak var installScrollView: NSScrollView!
    @IBOutlet weak var installOptionStackView: NSStackView!
    @IBOutlet weak var installButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func installRustup(_ sender: Any) {
        if self.installButton.title != "Install" {
            quit(sender)
        }
        
        self.installOutput.layoutManager?.allowsNonContiguousLayout = false
        let profile: InstallProfile = InstallProfile(string: profileButton.selectedItem!.identifier!.rawValue)!
        let noModifyPath = environmentCheckbox.state == .off
        installButton.isEnabled = false
        NSAnimationContext.runAnimationGroup {
            context in
            context.duration = 0.2
            context.allowsImplicitAnimation = true
            
            installOptionStackView.isHidden = true
            installScrollView.isHidden = false
        }
        
        try! Rustup.initialise(profile: profile, noModifyPath: noModifyPath) {
            line in
            DispatchQueue.main.async {
                self.installOutput.textStorage?.append(NSAttributedString(string: line.trimmingCharacters(in: .whitespaces)))
                let stringLength = self.installOutput.textStorage!.string.count
                self.installOutput.scrollRangeToVisible(NSMakeRange(stringLength-1, 0))
            }
        } finally: {
            status in
            DispatchQueue.main.async {
                self.installButton.isEnabled = true
                if status == 0 {
                    self.installButton.title = "Done"
                } else {
                    self.installButton.title = "Cancel"
                }
            }
        }
        
    }
    
    
    @IBAction func quit(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
}
