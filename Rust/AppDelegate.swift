//
//  AppDelegate.swift
//  Rust
//
//  Created by Erin Power on 08/02/2020.
//  Copyright © 2020 Rust. All rights reserved.
//

import Cocoa
import Toml

@objc enum ToolchainChannel: Int {
    case stable
    case beta
    case nightly

    var description: String {
        switch self {
        case .stable:
            return "stable"
        case .beta:
            return "beta"
        case .nightly:
            return "nightly"
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var preferencesWindow: NSWindowController? = nil

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        createLogo()
        createMenu()
    }

    func createLogo() {
        let logo = NSImage(named: NSImage.Name("status-logo"))!

        let resizedLogo = NSImage(size: NSSize(width: 22, height: 22), flipped: false) { (dstRect) -> Bool in
            logo.draw(in: dstRect)
            return true
        }

        statusItem.button!.image = resizedLogo
        statusItem.button!.action = #selector(createMenu)
    }

    @objc func createMenu() {
        let menu = NSMenu()

        let stable = NSMenuItem(title: "stable", action: #selector(setToolchainStable), keyEquivalent: "s")
        let beta = NSMenuItem(title: "beta", action: #selector(setToolchainBeta), keyEquivalent: "b")
        let nightly = NSMenuItem(title: "nightly", action: #selector(setToolchainNightly), keyEquivalent: "n")
        
        let settings = try! Toml(contentsOfFile: "/Users/ep/.rustup/settings.toml")
        if let default_toolchain = settings.string("default_toolchain") {
            if default_toolchain.contains("stable") {
                stable.state = .on
            } else if default_toolchain.contains("beta") {
                beta.state = .on
            } else if default_toolchain.contains("nightly") {
                nightly.state = .on
            }
        }

        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(stable)
        menu.addItem(beta)
        menu.addItem(nightly)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Targets", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        print(settings)

        statusItem.menu = menu
    }

    @objc func setToolchainStable() {
        setToolchainChannel(.stable)
    }

    @objc func setToolchainBeta() {
        setToolchainChannel(.beta)
    }

    @objc func setToolchainNightly() {
        setToolchainChannel(.nightly)
    }

    @objc func setToolchainChannel(_ channel: ToolchainChannel) {
        let rustupPath = "file:///Users/ep/.cargo/bin/rustup"
        try! Process.run(URL(string: rustupPath)!, arguments: ["default", "\(channel.description)"], terminationHandler: nil)
        resetChannelState()
        statusItem.menu?.item(withTitle: channel.description)?.state = .on
    }
    
    func resetChannelState() {
        statusItem.menu?.item(withTitle: ToolchainChannel.stable.description)?.state = .off
        statusItem.menu?.item(withTitle: ToolchainChannel.beta.description)?.state = .off
        statusItem.menu?.item(withTitle: ToolchainChannel.nightly.description)?.state = .off
    }

    @objc func showPreferences() {
        preferencesWindow?.close()
        NSApp.activate(ignoringOtherApps: true)
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        preferencesWindow = (storyboard.instantiateController(withIdentifier: "preferencesWindow") as! NSWindowController)
        preferencesWindow?.window?.center()
        preferencesWindow?.window?.collectionBehavior = .moveToActiveSpace
        preferencesWindow!.window?.makeKeyAndOrderFront(nil)
        preferencesWindow?.window?.orderFrontRegardless()

        preferencesWindow!.showWindow(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

