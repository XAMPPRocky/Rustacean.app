import Cocoa
import Toml
import Alamofire

fileprivate let RECENTLY_OPENED = "recently_opened"

func createMenuItem(title: String, action: Selector?, key charCode: String, target: AnyObject?) -> NSMenuItem {
    let menu = NSMenuItem(title: title, action: action, keyEquivalent: charCode)
    menu.target = target
    return menu
}

class ProjectMenuItem: NSMenuItem {
    var projectPath: URL!
    
    convenience init(url: URL) {
        self.init(title: url.lastPathComponent, action: #selector(openProjectPath), keyEquivalent: "")
        self.target = self
        self.projectPath = url
    }
    
    @objc func openProjectPath() {
        openUserEditor(projectPath)
    }
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
        let size = 21
        
        let logo = NSImage(named: NSImage.Name("status-logo"))!
        let logoInvert = NSImage(named: NSImage.Name("status-logo-inverted"))!

        let resizedLogo = NSImage(size: NSSize(width: size, height: size), flipped: false) { (dstRect) -> Bool in
            logo.draw(in: dstRect)
            return true
        }
        
        let resizedLogoInvert = NSImage(size: NSSize(width: size, height: size), flipped: false) { (dstRect) -> Bool in
            logoInvert.draw(in: dstRect)
            return true
        }

        statusItem.button!.image = resizedLogo
        statusItem.button!.alternateImage = resizedLogoInvert
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

        switch Rustup.channel() {
        case .stable:
            stable.state = .on
        case .beta:
            beta.state = .on
        case .nightly:
            nightly.state = .on
        }
        
        menu.addItem(createMenuItem(title: "New Project…", action: #selector(newProject), key: "n", target: self))
        menu.addItem(createMenuItem(title: "Open Project…", action: #selector(openProject), key: "o", target: self))
        menu.addItem(openProjectMenuItem())
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(createDocumentationMenu())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Channel", action: nil, keyEquivalent: ""))
        menu.addItem(stable)
        menu.addItem(beta)
        menu.addItem(nightly)
        menu.addItem(NSMenuItem.separator())
        //menu.addItem(createMenuItem(title: "Preferences…", action: #selector(showPreferences), key: "p", target: self))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }
    
    func openProjectMenuItem() -> NSMenuItem {
        let openProjectItem = createMenuItem(title: "Open Recent", action: nil, key: "", target: self)
        let items = UserDefaults.standard.array(forKey: RECENTLY_OPENED) as? [String] ?? []

        if !items.isEmpty {
            let menu = NSMenu()
            
            for path in items {
                menu.addItem(ProjectMenuItem(url: URL(string: path)!))
            }
            
            menu.addItem(NSMenuItem.separator())
            menu.addItem(createMenuItem(title: "Clear Menu", action: #selector(clearCache), key: "", target: self))
            
            openProjectItem.submenu = menu
        }
        
        return openProjectItem
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
    
    @objc func clearCache() {
        UserDefaults.standard.removeObject(forKey: RECENTLY_OPENED)
        createMainMenu()
    }
    
    @objc func newProject() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false

        if openPanel.runModal() == .OK {
            let url = openPanel.url!
            try! Cargo.create(url)
            
            openUserEditor(url)
            
            createMainMenu()
        }
    }

    @objc func openProject() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false

        if openPanel.runModal() == .OK {
            let url = openPanel.url!
            openUserEditor(url)
            createMainMenu()
        }
    }
}

/// Opens
func openUserEditor(_ url: URL) {
    let rustUrl = Bundle.main.url(forResource: "dummy", withExtension: "rs")!
    
    if let appURL = NSWorkspace.shared.urlForApplication(toOpen: rustUrl) {
        do {
            try NSWorkspace.shared.open([url], withApplicationAt: appURL, options: .default, configuration: [:])
            cacheItem(url)
        } catch _ {
            NSWorkspace.shared.open(url)
            cacheItem(url)
        }
    } else {
        NSWorkspace.shared.open(url)
        cacheItem(url)
    }
}

func cacheItem(_ url: URL) {
    var items = UserDefaults.standard.array(forKey: RECENTLY_OPENED) as? [String] ?? []
    
    if !items.contains(url.absoluteString) {
        items.insert(url.absoluteString, at: 0)
        UserDefaults.standard.set(Array(items.prefix(10)), forKey: RECENTLY_OPENED)
    }
}
