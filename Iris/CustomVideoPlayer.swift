
import SwiftUI
import AVKit

struct CustomVideoPlayer: NSViewRepresentable {
    var player: AVPlayer
    
    func makeNSView(context: Context) -> NSView {
        let view = VideoView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill // Zoom to fill
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? VideoView else { return }
        if view.playerLayer.player !== player {
            view.playerLayer.player = player
            view.playerLayer.videoGravity = .resizeAspectFill
        }
    }
    

    class VideoView: NSView {
        let playerLayer = AVPlayerLayer()
        
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            self.wantsLayer = true
            self.layer?.addSublayer(playerLayer)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layout() {
            super.layout()
            playerLayer.frame = self.bounds
        }
    }
}
