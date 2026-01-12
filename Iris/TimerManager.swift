
import SwiftUI
import Combine
import AppKit

enum AppState {
    case working
    case onBreak
    case paused
}

class TimerManager: ObservableObject {
    @Published var appState: AppState = .working
    @Published var isBreakWindowVisible: Bool = false
    @Published var timeRemaining: TimeInterval = 20 * 60
    @Published var currentMediaURL: URL?
    @Published var mediaURL: URL? // For ContentView display
    
    // Settings
    @AppStorage("workInterval") var workInterval: TimeInterval = 20 * 60
    @AppStorage("breakInterval") var breakInterval: TimeInterval = 60
    @AppStorage("totalBreaks") var totalBreaks: Int = 0
    @AppStorage("mediaBookmark") private var mediaBookmarkData: Data?
    
    private var timer: Timer?
    private var workEndTime: Date?
    private var playlist: [URL] = []
    private var scopedSessionURLs: Set<URL> = []
    private let supportedVideoExtensions: Set<String> = ["mp4", "mov", "m4v", "mkv"]
    
    init() {
        loadPlaylist()
        startWorkTimer(reset: true)
     
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(handlePauseEvent), name: NSWorkspace.willSleepNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleResumeEvent), name: NSWorkspace.didWakeNotification, object: nil)
        nc.addObserver(self, selector: #selector(handlePauseEvent), name: NSWorkspace.screensDidSleepNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleResumeEvent), name: NSWorkspace.screensDidWakeNotification, object: nil)
    }
    
    deinit {
        releaseScopedResources()
    }
    
    private func releaseScopedResources() {
        scopedSessionURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        scopedSessionURLs.removeAll()
    }
    
    private func addToPlaylistIfReachable(_ url: URL, source: String) {
        if url.startAccessingSecurityScopedResource() {
            scopedSessionURLs.insert(url)
            playlist.append(url)
        } else if FileManager.default.isReadableFile(atPath: url.path) {
            playlist.append(url)
        } else {
            print("Could not open() the item: \(url.path) [source: \(source)]")
        }
    }
    
    private func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }
    
    private func collectMedia(from url: URL, source: String) {
        if isDirectory(url) {
            if url.startAccessingSecurityScopedResource() {
                scopedSessionURLs.insert(url)
            }
            do {
                let files = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
                for file in files where supportedVideoExtensions.contains(file.pathExtension.lowercased()) {
                    playlist.append(file)
                }
                if files.isEmpty {
                    print("Selected folder is empty: \(url.path)")
                }
            } catch {
                print("Failed to list media in folder: \(error)")
            }
        } else {
            addToPlaylistIfReachable(url, source: source)
        }
    }
    
    private func defaultMediaCandidates() -> [URL] {
        var candidates: [URL] = []
        if let bundled = Bundle.main.url(forResource: "clip1_final", withExtension: "mp4") {
            candidates.append(bundled)
        }
        let home = FileManager.default.homeDirectoryForCurrentUser
        let names = ["clip1_final.mp4", "clip1.mkv", "clip2.mkv", "clip3.mkv", "clip1.mp4", "clip2.mp4", "clip3.mp4"]
        candidates.append(contentsOf: names.map { home.appendingPathComponent($0) })
        return candidates
    }
    
    private func loadPlaylist() {
        releaseScopedResources()
        playlist = []
        
     
        if let url = mediaURL {
            collectMedia(from: url, source: "session media selection")
        }
       
        if playlist.isEmpty, let data = mediaBookmarkData {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
                if isStale {
                    print("Bookmark is stale; will refresh when user re-selects media")
                }
                if FileManager.default.fileExists(atPath: url.path) {
                    collectMedia(from: url, source: "saved bookmark")
                } else {
                    print("Bookmark target missing: \(url.path)")
                }
            } catch {
                print("Failed to resolve bookmark: \(error)")
                mediaBookmarkData = nil
            }
        }
        
      
        if playlist.isEmpty {
            for candidate in defaultMediaCandidates() where FileManager.default.fileExists(atPath: candidate.path) {
                collectMedia(from: candidate, source: "default fallback")
            }
        }
        
        if !playlist.isEmpty {
            print("Loaded \(playlist.count) video(s) into playlist")
        } else {
            print("No videos found in playlist")
        }
    }
    
    func startWorkTimer(reset: Bool = true) {
        stopTimer()
        MediaController.shared.resumeIfNeeded()
        appState = .working
        isBreakWindowVisible = false
        
        if reset {
            timeRemaining = workInterval
        }
        
        // Efficient Timer
        workEndTime = Date().addingTimeInterval(timeRemaining)
        let interval = timeRemaining
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.startBreak()
        }
        timer?.tolerance = 1.0
    }
    
    func startBreak() {
        stopTimer()
        appState = .onBreak
        timeRemaining = breakInterval
        isBreakWindowVisible = true
        workEndTime = nil
        MediaController.shared.pauseIfPlaying()
        
       
        loadPlaylist()
        
        if !playlist.isEmpty {
            currentMediaURL = playlist.randomElement()
            print("Selected video for break: \(currentMediaURL?.lastPathComponent ?? "none")")
        } else {
            currentMediaURL = nil
            print("No videos found in playlist")
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tickBreak()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func skipBreak() {
        MediaController.shared.resumeIfNeeded()
        startWorkTimer(reset: true)
    }
    
    private func tickBreak() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            totalBreaks += 1
            MediaController.shared.resumeIfNeeded()
            startWorkTimer(reset: true)
        }
    }
    
    @objc func handlePauseEvent() {
        if appState == .working, let endTime = workEndTime {
            let remaining = endTime.timeIntervalSince(Date())
            timeRemaining = max(0, remaining)
        }
        stopTimer()
        appState = .paused
    }
    
    @objc func handleResumeEvent() {
        if appState == .paused || appState == .working {
            startWorkTimer(reset: false)
        }
    }
    
    
    func updateMediaSelection(url: URL) {
        mediaURL = url
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer { if didStartAccess { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            mediaBookmarkData = data
            print("Updated media selection (persistent): \(url.lastPathComponent)")
        } catch {
            mediaBookmarkData = nil
            print("Failed to save bookmark (session only): \(error)")
        }
        loadPlaylist()
    }
    
    func clearMediaSelection() {
        mediaBookmarkData = nil
        mediaURL = nil
        loadPlaylist()
    }
}
