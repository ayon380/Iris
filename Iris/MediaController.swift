
import AppKit
import Foundation
import MediaPlayer
import CoreGraphics

class MediaController {
    static let shared = MediaController()
    private var wasPlayingBeforeBreak: Bool = false
    private var pausedByApp: Bool = false
    
    private init() {}
    
    func pauseIfPlaying() {
        wasPlayingBeforeBreak = isSomethingPlaying()
        pausedByApp = false
        if wasPlayingBeforeBreak {
            sendPlayPauseKey()
            pausedByApp = true
        }
    }
    
    func resumeIfNeeded() {
        if pausedByApp {
            sendPlayPauseKey()
            pausedByApp = false
            wasPlayingBeforeBreak = false
        }
    }
    
    private func isSomethingPlaying() -> Bool {
        if #available(macOS 12.0, *) {
            if let info = MPNowPlayingInfoCenter.default().nowPlayingInfo {
                if let rate = info[MPNowPlayingInfoPropertyPlaybackRate] as? NSNumber {
                    return rate.doubleValue > 0.01
                }
                return false
            }
        }
        return false
    }
    
    private func sendPlayPauseKey() {
        
        let source = CGEventSource(stateID: .hidSystemState)
        func postKey(flags: CGEventFlags = []) {
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 100, keyDown: true) {
                keyDown.flags = flags
                keyDown.post(tap: .cghidEventTap)
            }
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 100, keyDown: false) {
                keyUp.flags = flags
                keyUp.post(tap: .cghidEventTap)
            }
        }
        postKey(flags: .maskSecondaryFn)
        postKey()
    }
}
