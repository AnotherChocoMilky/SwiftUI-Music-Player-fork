import SwiftUI
import AVKit

struct ModernMusicPlayer: View {
    // MARK: - Properties
    let audioFile = "piano"
    
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var totalTime: TimeInterval = 0.0
    @State private var currentTime: TimeInterval = 0.0
    @State private var isDragging = false
    
    // Animation States
    @State private var albumRotation: Double = 0
    @State private var albumScale: CGFloat = 0.85
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(colors: [Color(hex: "1a1a2e"), Color(hex: "0f0f1b")], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            // Animated Ambient Glow
            GeometryReader { geo in
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: isPlaying ? 50 : -50, y: isPlaying ? 100 : 200)
                    .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: isPlaying)
            }
            
            VStack(spacing: 25) {
                // Header
                HStack {
                    GlassButton(icon: "chevron.down")
                    Spacer()
                    Text("Now Playing")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    GlassButton(icon: "list.bullet")
                }
                .padding(.horizontal)
                
                // Album Art Container
                VStack {
                    ZStack {
                        // Shadow Glow
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 260, height: 260)
                            .blur(radius: 40)
                            .opacity(isPlaying ? 1 : 0)
                        
                        Image("tree") // Ensure "tree" is in Assets
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 280, height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .scaleEffect(isPlaying ? 1.0 : 0.9)
                    }
                }
                .padding(.vertical, 30)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: isPlaying)
                
                // Track Info
                VStack(spacing: 8) {
                    Text("Drift")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Robot Koch ft. nilu")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Slider & Time
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
                
                // Controls
                HStack(spacing: 40) {
                    Button(action: {}) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                    }
                    
                    // Main Play Button
                    Button(action: togglePlay) {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 80, height: 80)
                                .shadow(color: .white.opacity(0.2), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundColor(.black)
                                .offset(x: isPlaying ? 0 : 2)
                        }
                    }
                    .buttonStyle(StaticButtonStyle())
                    
                    Button(action: {}) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                    }
                }
                .foregroundColor(.white)
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.top)
        }
        .onAppear(perform: setupAudio)
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            updateProgress()
        }
    }
    
    // MARK: - Logic Helpers
    private func setupAudio() {
        guard let url = Bundle.main.url(forResource: audioFile, withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            totalTime = player?.duration ?? 0.0
        } catch {
            print("Audio error")
        }
    }
    
    private func togglePlay() {
        withAnimation(.spring()) {
            if isPlaying {
                player?.pause()
            } else {
                player?.play()
            }
            isPlaying.toggle()
        }
    }
    
    private func updateProgress() {
        guard let player = player, !isDragging else { return }
        currentTime = player.currentTime
        if currentTime >= totalTime - 0.1 { isPlaying = false }
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

// MARK: - Subviews & Styling

struct GlassButton: View {
    var icon: String
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(12)
            .background(
                Circle()
                    .fill(.white.opacity(0.1))
                    .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
            )
    }
}

struct CustomSlider: View {
    @Binding var value: TimeInterval
    var range: ClosedRange<TimeInterval>
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 6)
                
                Capsule()
                    .fill(
                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geo.size.width, height: 6)
                
                Circle()
                    .fill(.white)
                    .frame(width: 14, height: 14)
                    .offset(x: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geo.size.width - 7)
                    .shadow(radius: 4)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let percent = min(max(0, gesture.location.x / geo.size.width), 1)
                        value = range.lowerBound + Double(percent) * (range.upperBound - range.lowerBound)
                    }
            )
        }
        .frame(height: 14)
    }
}

// Prevents button flash during animation
struct StaticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Helper for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

#Preview {
    ModernMusicPlayer()
}
