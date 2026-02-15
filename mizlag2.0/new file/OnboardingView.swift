import Foundation
import SwiftUI
import AVFoundation
import AVKit

// MARK: - Main Onboarding View
struct OnboardingView: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var videoPlayer = AVPlayer()
    @State private var showLogoPage = true
    @State private var showGame = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if showLogoPage {
                    ZStack {
                        VideoPlayer(player: videoPlayer)
                            .disabled(true)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                        
                        VStack {
                            Spacer()
                            Image("r")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .shadow(color: .white.opacity(0.8), radius: 10)
                            Spacer()
                        }
                    }
                    .transition(.opacity)
                }

                if showGame {
                    NextPageView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onAppear {
                startIntroSequence()
            }
            .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
                videoPlayer.seek(to: .zero)
                videoPlayer.play()
            }
        }
        .ignoresSafeArea()
    }
    
    private func startIntroSequence() {
        setupAudioSession()
        playAudio()
        prepareIntroVideo()
        videoPlayer.play()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                showLogoPage = false
                showGame = true
            }
        }
    }

    private func prepareIntroVideo() {
        guard let url = Bundle.main.url(forResource: "v", withExtension: "mov") ??
                        Bundle.main.url(forResource: "v", withExtension: "mp4") else { return }
        videoPlayer.replaceCurrentItem(with: AVPlayerItem(url: url))
        videoPlayer.isMuted = true
    }

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }
    
    private func playAudio() {
        guard let url = Bundle.main.url(forResource: "h", withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
        } catch {
            print("Audio error: \(error)")
        }
    }
}

// MARK: - Single Video View (v4 Only)
struct NextPageView: View {
    @State private var showDossier = false
    @State private var player = AVPlayer()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geo in
                VideoContainerView(player: player)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(1.1)
            }
            .ignoresSafeArea()
            .blur(radius: showDossier ? 8 : 0)
            .animation(.easeInOut(duration: 0.2), value: showDossier)
            
            VStack {
                if !showDossier {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showDossier = true
                            }
                        }) {
                            Image("erqa")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 160, height: 160)
                                .rotationEffect(.degrees(-3))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .offset(x: -165, y: -60)
                        Spacer()
                    }
                    .padding(.bottom, 50)
                }
            }
            
            if showDossier {
                DossierOverlay(isPresented: $showDossier)
                    .transition(.opacity)
            }
        }
        .onAppear {
            setupPlayer()
        }
    }
    
    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: "v4", withExtension: "mp4") ??
                        Bundle.main.url(forResource: "v4", withExtension: "mov") else {
            return
        }
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.isMuted = true
        player.play()
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: item,
                                               queue: .main) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
}

// MARK: - Reusable Components

struct SolidInstantButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
    }
}

struct DossierOverlay: View {
    @Binding var isPresented: Bool
    
    private let staticText = """
      قبل ما يقفل مستشفى عرقه،
      كان فيه جناح ما تقفل بشكل رسمي.
      الجناح رقم صفر.
      المرضى فيه ما كانوا يُسجَّلون بأسماء.
      كانوا يُسجَّلون بأرقام.
      آخر ملاحظة محفوظة في السجلات تقول:
      """
    private let animatedTextGoal = "“المرضى لم يخرجوا…هم بقوا هنا.”"
    
    @State private var displayedAnimatedText = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            
            Image("oldp")
                .resizable()
                .scaledToFit()
                .frame(width: 700)
            
            Image("Image")
                .resizable()
                .scaledToFit()
                .frame(width: 900)
                .padding(.trailing, -40)
                .padding(.bottom, 0)
                .offset(y: 20)
                .offset(x: 50)
           
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        print("Game Started!")
                    }) {
                        Text("العب")
                            .font(.system(size: 20, weight: .black, design: .serif))
                            .foregroundColor(.be)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.burgandy)
                            )
                            .shadow(radius: 8)
                    }
                    .buttonStyle(SolidInstantButtonStyle())
                    .padding(.leading, 220) // مسافة بسيطة عن حافة الشاشة اليسرى
                    
                    Spacer() // يدفع الزر لليسار
                }
                .padding(.bottom, 50)
            }
            
            VStack {
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) { isPresented = false }
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 45))
                            .foregroundColor(.be)
                    }
                    .padding(30)
                    Spacer()
                }
                Spacer()
            }
        }
        .transition(.opacity)
        .onAppear {
            startTypingAnimation()
        }
    }
    
    private func startTypingAnimation() {
        displayedAnimatedText = ""
        let characters = Array(animatedTextGoal)
        var index = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if index < characters.count {
                displayedAnimatedText.append(characters[index])
                index += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

struct VideoContainerView: View {
    var player: AVPlayer
    var body: some View {
        VideoPlayer(player: player)
            .disabled(true)
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .ignoresSafeArea()
    }
}

// Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
