import SwiftUI
import AVKit
import UniformTypeIdentifiers

struct BreakView: View {
    @ObservedObject var manager: TimerManager
    @State private var player: AVPlayer?
    @State private var loadError: String?
    @State private var isVisible: Bool = false
    
    // Aesthetic constants
    private let glassCornerRadius: CGFloat = 32
    
    var body: some View {
        ZStack {
            // 1. Background Layer (Video / Image / Gradient)
            mediaBackground
            
            // 2. Interface Layer
            VStack {
                Spacer() // Pushes content to bottom
                
                HStack {
                    glassControlPanel
                    Spacer() // Pushes content to left
                }
                .padding(.leading, 40) // MacOS style generous margins
                .padding(.bottom, 40)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.smooth(duration: 0.5), value: isVisible) // 'Smooth' is newer and more organic than easeInOut
        .onAppear {
            isVisible = true
            prepareMedia(for: manager.currentMediaURL)
        }
        .onChange(of: manager.currentMediaURL) { oldValue, newValue in
            prepareMedia(for: newValue)
        }
        .onChange(of: manager.isBreakWindowVisible) { _, visible in
            if visible {
                isVisible = true
                prepareMedia(for: manager.currentMediaURL)
            } else {
                isVisible = false
                stopPlayback()
            }
        }
        .onDisappear {
            isVisible = false
            stopPlayback()
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { notification in
            if let playerItem = notification.object as? AVPlayerItem,
               let currentItem = player?.currentItem,
               playerItem == currentItem {
                player?.seek(to: .zero)
                player?.play()
            }
        }
    }
    
    // MARK: - Liquid Glass Panel
    var glassControlPanel: some View {
        HStack(spacing: 24) {
            // Info Section
            VStack(alignment: .leading, spacing: 2) {
                Text("REST YOUR EYES 👀")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(1.5) // Adds letter spacing for that clean premium look
                Text("Look Far Away at 20ft")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(timeString(from: manager.timeRemaining))
                    .font(.system(size: 100, weight: .medium, design: .rounded))
                    .monospacedDigit() // Prevents timer jitter
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            
            // Vertical Separator
            Divider()
                .frame(height: 140)
                .overlay(.secondary.opacity(0.2))
            
            // Stop/Skip Button
            Button(action: {
                stopPlayback()
                manager.skipBreak()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.red.gradient) // Rich gradient
                        .shadow(color: .red.opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 50, height: 50)
            }
            .buttonStyle(.plain)
            .help("Skip Break")
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        // THE LIQUID GLASS EFFECT
//        .glassEffect()
        .clipShape(RoundedRectangle(cornerRadius: glassCornerRadius, style: .continuous))
//        .overlay(
//            RoundedRectangle(cornerRadius: glassCornerRadius, style: .continuous)
//                .stroke(
//                    LinearGradient(
//                        colors: [.white.opacity(0.6), .white.opacity(0.1)],
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    ),
//                    lineWidth: 1
//                )
//        )
        .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 15) // Deep, soft shadow
        .glassEffect(in: RoundedRectangle(cornerRadius: glassCornerRadius, style: .continuous))
    }
    
    // MARK: - Media Components
    @ViewBuilder
    private var mediaBackground: some View {
        if let player = player {
            CustomVideoPlayer(player: player)
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear { player.play() }
        } else if let url = manager.currentMediaURL, let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        } else {
            // "Aurora" Default Background
            ZStack {
                LinearGradient(
                    colors: [Color(nsColor: .systemIndigo), Color(nsColor: .systemTeal)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(.black.opacity(0.2)) // Slight dim to make text pop
                
                VStack(spacing: 20) {
                    Image(systemName: "eye.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)
                        .font(.system(size: 90))
                        .shadow(radius: 10)
                    
                    Text("Time to Relax")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                }
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Logic Helpers
    private func stopPlayback() {
        player?.pause()
        player = nil
    }
    
    private func prepareMedia(for url: URL?) {
        stopPlayback()
        loadError = nil
        
        guard let url = url else { return }
        let path = url.path.lowercased()
        
        // Simple validation
        if path.hasSuffix(".mkv") {
            loadError = "MKV format is not natively supported."
            return
        }
        
        let isVideo = path.hasSuffix(".mp4") || path.hasSuffix(".mov") || path.hasSuffix(".m4v")
        
        if isVideo {
            let playerItem = AVPlayerItem(url: url)
            let newPlayer = AVPlayer(playerItem: playerItem)
            newPlayer.actionAtItemEnd = .none
            newPlayer.volume = 1.0
            // Prevent other audio from ducking if desired, or handle audio session here
            self.player = newPlayer
            newPlayer.play()
        } else {
            // Assume image or unsupported
        }
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
