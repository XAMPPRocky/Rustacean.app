//
//  AppDelegate.swift
//  Rust
//
//  Created by Erin Power on 08/02/2020.
//  Copyright © 2020 Rust. All rights reserved.
//

import Cocoa

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

        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Stable", action: nil, keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Beta", action: nil, keyEquivalent: "b"))
        menu.addItem(NSMenuItem(title: "Nightly", action: nil, keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
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

