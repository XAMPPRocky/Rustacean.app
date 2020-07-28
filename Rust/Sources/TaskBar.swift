import Cocoa
import Toml
import Alamofire

func createMenuItem(title: String, action: Selector?, key charCode: String, target: AnyObject?) -> NSMenuItem {
    let menu = NSMenuItem(title: title, action: action, keyEquivalent: charCode)
    menu.target = target
    return menu
}

class TaskBar {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let manager = NetworkReachabilityManager(host: "doc.rust-lang.org")
    
    init() {
        createLogo()
        createMainMenu()
    }

    // MARK: Logo
    func createLogo() {
        let logo = NSImage(named: NSImage.Name("status-logo"))!

        let resizedLogo = NSImage(size: NSSize(width: 22, height: 22), flipped: false) { (dstRect) -> Bool in
            logo.draw(in: dstRect)
            return true
        }

        statusItem.button!.image = resizedLogo
    }

    // MARK: Channels
    class ChannelMenuItem: NSMenuItem {
        var channel: ToolchainChannel? = nil
        
        convenience init(channel: ToolchainChannel, action: Selector, target: AnyObject?) {
            self.init(title: channel.description, action: action, keyEquivalent: channel.shortcutKey)
            self.target = target
        }
    }
    
    @objc func setToolchainStable() { setToolchainChannel(.stable) }
    @objc func setToolchainBeta() { setToolchainChannel(.beta) }
    @objc func setToolchainNightly() { setToolchainChannel(.nightly) }

    @objc func setToolchainChannel(_ channel: ToolchainChannel) {
        Rustup.set(channel: channel) {
            _ in
            self.resetChannelState()
            self.statusItem.menu!.item(withTitle: channel.description)?.state = .on
        }
    }

    func resetChannelState() {
        for channel in ToolchainChannel.all {
            statusItem.menu!.item(withTitle: channel.description)?.state = .off
        }
    }
    
    // MARK: Main Menu
    func createMainMenu() {
        let menu = NSMenu()

        let stable = ChannelMenuItem(channel: .stable, action: #selector(setToolchainStable), target: self)
        let beta = ChannelMenuItem(channel: .beta, action: #selector(setToolchainBeta), target: self)
        let nightly = ChannelMenuItem(channel: .nightly, action: #selector(setToolchainNightly), target: self)

        /*
        switch Rustup.channel() {
        case .stable:
            stable.state = .on
        case .beta:
            beta.state = .on
        case .nightly:
            nightly.state = .on
        }
        */
        
        // menu.addItem(NSMenuItem(title: "New Project...", action: nil, keyEquivalent: ""))
        // menu.addItem(NSMenuItem(title: "Open Project...", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(createDocumentationMenu())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Channel", action: nil, keyEquivalent: ""))
        menu.addItem(stable)
        menu.addItem(beta)
        menu.addItem(nightly)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(createMenuItem(title: "Preferences...", action: #selector(showPreferences), key: "p", target: self))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // MARK: Documentation Menu
    func createDocumentationMenu() -> NSMenuItem {
        let documentation = createMenuItem(title: "Documentation", action: nil, key: "", target: self)
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "API Docs", action: nil, keyEquivalent: ""))
        menu.addItem(createMenuItem(title: "std", action: #selector(openStd), key: "", target: self))
        menu.addItem(createMenuItem(title: "alloc", action: #selector(openAlloc), key: "", target: self))
        menu.addItem(createMenuItem(title: "core", action: #selector(openCore), key: "", target: self))
        menu.addItem(createMenuItem(title: "proc_macro", action: #selector(openProcMacro), key: "", target: self))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Books", action: nil, keyEquivalent: ""))
        menu.addItem(createMenuItem(title: "Cargo", action: #selector(openCargoBook), key: "", target: self))
        menu.addItem(createMenuItem(title: "Edition Guide", action: #selector(openEditionBook), key: "", target: self))
        menu.addItem(createMenuItem(title: "Embedded Rust", action: #selector(openEmbeddedBook), key: "", target: self))
        menu.addItem(createMenuItem(title: "Nomicon", action: #selector(openNomicon), key: "", target: self))
        menu.addItem(createMenuItem(title: "Reference", action: #selector(openReference), key: "", target: self))
        menu.addItem(createMenuItem(title: "Rust By Example", action: #selector(openRustByExample), key: "", target: self))
        menu.addItem(createMenuItem(title: "Rustdoc Guide", action: #selector(openRustdoc), key: "", target: self))
        menu.addItem(createMenuItem(title: "Rustc Guide", action: #selector(openRustcBook), key: "", target: self))
        menu.addItem(createMenuItem(title: "The Rust Programming Language", action: #selector(openBook), key: "", target: self))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Unstable", action: nil, keyEquivalent: ""))
        menu.addItem(createMenuItem(title: "Testing Framework", action: #selector(openTestDoc), key: "", target: self))
        menu.addItem(createMenuItem(title: "Nightly Features", action: #selector(openUnstableBook), key: "", target: self))
        menu.addItem(NSMenuItem.separator())

        documentation.submenu = menu
        
        return documentation
    }

    @objc func openAlloc() { openDoc("alloc", "https://doc.rust-lang.org/alloc") }
    @objc func openBook() { openDoc("book", "https://doc.rust-lang.org/book") }
    @objc func openCargoBook() { openDoc("cargo", "https://doc.rust-lang.org/cargo") }
    @objc func openCore() { openDoc("core", "https://doc.rust-lang.org/core") }
    @objc func openEditionBook() { openDoc("edition-guide", "https://doc.rust-lang.org/edition-guide") }
    @objc func openEmbeddedBook() { openDoc("embedded-book", "https://doc.rust-lang.org/embedded-book") }
    @objc func openNomicon() { openDoc("nomicon", "https://doc.rust-lang.org/nomicon") }
    @objc func openProcMacro() { openDoc("proc_macro", "https://doc.rust-lang.org/proc_macro") }
    @objc func openReference() { openDoc("reference", "https://doc.rust-lang.org/reference") }
    @objc func openRustByExample() { openDoc("rust-by-example", "https://doc.rust-lang.org/rust-by-example") }
    @objc func openRustcBook() { openDoc("rustc", "https://doc.rust-lang.org/rustc") }
    @objc func openRustdoc() { openDoc("rustdoc", "https://doc.rust-lang.org/rustdoc") }
    @objc func openStd() { openDoc("std", "https://doc.rust-lang.org/std") }
    @objc func openTestDoc() { openDoc("test", "https://doc.rust-lang.org/proc_macro") }
    @objc func openUnstableBook() { openDoc("unstable-book", "https://doc.rust-lang.org/unstable-book") }

    @objc func openDoc(_ resource: String, _ url: String) {
        if case .reachable(_)? = manager?.status {
            NSWorkspace.shared.open(URL(string: url)!)
        } else {
            Rustup.output(["doc", "--\(resource)"]) { _ in }
        }
    }

    // MARK: Show Preferences
    @objc func showPreferences() {
        if let window = AppDelegate.preferencesWindow {
            window.showWindow(self)
            return
        }
        NSApp.activate(ignoringOtherApps: true)
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        AppDelegate.preferencesWindow = (storyboard.instantiateController(withIdentifier: "preferencesWindow") as! NSWindowController)
        AppDelegate.preferencesWindow?.window?.title = "Rust"
        AppDelegate.preferencesWindow?.window?.center()
        AppDelegate.preferencesWindow?.window?.collectionBehavior = .moveToActiveSpace
        AppDelegate.preferencesWindow!.window?.makeKeyAndOrderFront(nil)
        AppDelegate.preferencesWindow?.window?.orderFrontRegardless()

        AppDelegate.preferencesWindow!.showWindow(self)
    }
}
