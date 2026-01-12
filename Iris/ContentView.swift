
import SwiftUI
import Combine
import UniformTypeIdentifiers
import CoreGraphics

struct ContentView: View {
    @ObservedObject var manager: TimerManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "eye.circle.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
                Text("Iris")
                    .font(.headline)
                Spacer()
                
                Text(manager.appState == .working ? "Working" : "Break")
                    .font(.caption)
                    .padding(10)
                    
                    .foregroundColor(manager.appState == .working ? .green : .orange)
            }
            
            Divider()
            
            // Stats (Local)
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Stats")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.blue)
                    Text("Breaks Taken:")
                    Spacer()
                    Text("\(manager.totalBreaks)")
                        .bold()
                }
                .font(.callout)
            }
            
            Divider()
            
            // Settings
            VStack(alignment: .leading, spacing: 15) {
                Text("Timer Settings")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Work Interval")
                        Spacer()
                        Text("\(Int(manager.workInterval / 60)) min")
                            .foregroundStyle(.secondary)
                    }
                    // Restart timer on change if working
                    HStack(spacing: 20) { // Adjust '20' to increase/decrease space
                        Text("Work")
                        
                        Slider(value: $manager.workInterval, in: 300...3600, step: 300)
                    }
                    .onChange(of: manager.workInterval) {oldval, newValue in
                        if manager.appState == .working {
                            manager.startWorkTimer(reset: true)
                        }
                    }
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Break Duration")
                        Spacer()
                        Text("\(Int(manager.breakInterval)) sec")
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 17) { // Adjust '20' to change the gap size
                        Text("Break")
                        
                        Slider(value: $manager.breakInterval, in: 20...300, step: 20)
                    }
                }
            }
            
            Divider()
            
            // Media Selection
            VStack(alignment: .leading, spacing: 10) {
                Text("Break Content")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                
                HStack {
                    if let url = manager.mediaURL {
                        Label(url.lastPathComponent, systemImage: "play.tv")
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("No media selected")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Choose...") {
                        pickMedia()
                    }
                }
            }
            .font(.callout)
            
            Divider()
            
            // Actions
            HStack {
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                }
                .help("Quit App")
                
                Spacer()
                
                if manager.appState == .working {
                    Button("Start Break Now") {
                        manager.startBreak()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("End Break") {
                        manager.skipBreak()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .frame(width: 320)
    }
    
    private func pickMedia() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image, .movie, .folder]
        if panel.runModal() == .OK, let url = panel.url {
            manager.updateMediaSelection(url: url)
        }
    }
}

#Preview {
    ContentView(manager: TimerManager())
}
