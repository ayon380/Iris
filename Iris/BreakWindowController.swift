import AppKit
import SwiftUI

class BreakWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class BreakWindowController: NSWindowController {
    
    convenience init(manager: TimerManager) {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let window = BreakWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        // window.ignoresMouseEvents = true // Removed to allow interaction with buttons
        
        let contentView = NSHostingView(rootView: BreakView(manager: manager))
        window.contentView = contentView
        
        self.init(window: window)
        window.alphaValue = 0.0
    }
    
    func show() {
        guard let window = window else { return }
        // Update frame in case of screen changes
        if let screen = NSScreen.main {
            window.setFrame(screen.frame, display: true)
        }
        window.alphaValue = 0.0
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            window.animator().alphaValue = 1.0
        }
    }
    
    func hide() {
        guard let window = window else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            window.animator().alphaValue = 0.0
        }, completionHandler: {
            window.orderOut(nil)
            window.alphaValue = 1.0
        })
    }
}
