import SwiftUI
import AVKit
import UniformTypeIdentifiers

struct ModernMusicPlayer: View {
    // MARK: - Properties
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var totalTime: TimeInterval = 0.0
    @State private var currentTime: TimeInterval = 0.0
    
    // File Selection States
    @State private var isShowingPicker = false
    @State private var selectedFileName: String = "No Track Selected"
    @State private var selectedArtist: String = "Tap the '+' to upload"
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [Color(hex: "0f0f1b"), Color(hex: "1a1a2e")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Header with Upload Button
                HStack {
                    GlassButton(icon: "music.note.list")
                    Spacer()
                    Text("My Library")
                        .font(.system(.subheadline, design: .rounded)).bold()
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    
                    // THE UPLOAD BUTTON
                    Button(action: { isShowingPicker = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.linearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom))
                    }
                }
                .padding(.horizontal)
                
                // Album Art (Pulse Animation)
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 280, height: 280)
                        .blur(radius: isPlaying ? 40 : 20)
                        .scaleEffect(isPlaying ? 1.2 : 1.0)
                    
                    // If no file is picked, show a placeholder icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(.white.opacity(0.05))
                            .frame(width: 260, height: 260)
                            .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.1), lineWidth: 1))
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.2))
                    }
                }
                .padding(.vertical, 20)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPlaying)
                
                // Track Info (Updated by File Name)
                VStack(spacing: 8) {
                    Text(selectedFileName)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text(selectedArtist)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Slider
                VStack(spacing: 12) {
                    CustomSlider(value: Binding(get: {
                        currentTime
                    }, set: { newValue in
                        currentTime = newValue
                        audioTime(to: newValue)
                    }), range: 0...totalTime)
                    
                    HStack {
                        Text(timeString(time: currentTime))
                        Spacer()
                        Text(timeString(time: totalTime))
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 30)
                
                // Main Controls
                HStack(spacing: 50) {
                    Image(systemName: "backward.fill").font(.title2)
                    
                    Button(action: togglePlay) {
                        Circle()
                            .fill(.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .foregroundColor(.black).font(.title)
                            )
                    }
                    .buttonStyle(StaticButtonStyle())
                    
                    Image(systemName: "forward.fill").font(.title2)
                }
                .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.top)
        }
        // FILE PICKER MODIFIER
        .fileImporter(
            isPresented: $isShowingPicker,
            allowedContentTypes: [.audio, .mp3, .mpeg4Audio, .wav],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                loadAudio(from: url)
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            updateProgress()
        }
    }
    
    // MARK: - Logic
    private func loadAudio(from url: URL) {
        // 1. Gain permission to read the external file
        guard url.startAccessingSecurityScopedResource() else { return }
        
        // 2. Clear old player
        player?.stop()
        isPlaying = false
        
        do {
            // 3. Initialize player with the selected URL
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            
            // 4. Update UI labels
            totalTime = player?.duration ?? 0.0
            selectedFileName = url.deletingPathExtension().lastPathComponent
            selectedArtist = "Local Audio File"
            
            // 5. Auto-play
            togglePlay()
            
        } catch {
            print("Failed to load audio")
        }
        
        // Important: Stop accessing resource when done loading (player keeps its own copy)
        url.stopAccessingSecurityScopedResource()
    }
    
    private func togglePlay() {
        guard player != nil else { return }
        withAnimation(.spring()) {
            if isPlaying { player?.pause() } 
            else { player?.play() }
            isPlaying.toggle()
        }
    }
    
    private func updateProgress() {
        guard let player = player else { return }
        currentTime = player.currentTime
    }
    
    private func audioTime(to time: TimeInterval) {
        player?.currentTime = time
    }
    
    private func timeString(time: TimeInterval) -> String {
        let minute = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minute, seconds)
    }
}

// MARK: - Support Views (Same as before but kept for completeness)
struct GlassButton: View {
    var icon: String
    var body: some View {
        Image(systemName: icon).padding(12)
            .background(Circle().fill(.white.opacity(0.1)))
            .foregroundColor(.white)
    }
}

struct CustomSlider: View {
    @Binding var value: TimeInterval
    var range: ClosedRange<TimeInterval>
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1)).frame(height: 6)
                Capsule()
                    .fill(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                    .frame(width: CGFloat((value - range.lowerBound) / (max(1, range.upperBound - range.lowerBound))) * geo.size.width, height: 6)
            }
            .gesture(DragGesture(minimumDistance: 0).onChanged { gesture in
                let percent = min(max(0, gesture.location.x / geo.size.width), 1)
                value = range.lowerBound + Double(percent) * (range.upperBound - range.lowerBound)
            })
        }.frame(height: 6)
    }
}

struct StaticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.9 : 1.0).animation(.easeOut, value: configuration.isPressed)
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
