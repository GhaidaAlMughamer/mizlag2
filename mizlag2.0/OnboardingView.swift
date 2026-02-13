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

// MARK: - Swipable Gallery View
struct NextPageView: View {
    @State private var currentPage = 0
    @State private var showDossier = false
    
    @State private var player2 = AVPlayer()
    @State private var player3 = AVPlayer()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentPage) {
                VideoContainerView(player: player2).tag(0)
                VideoContainerView(player: player3).tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .blur(radius: showDossier ? 8 : 0)
            .animation(.easeInOut(duration: 0.2), value: showDossier)
            .ignoresSafeArea()

            if !showDossier {
                HStack {
                    Button(action: {
                        withAnimation { if currentPage > 0 { currentPage -= 1 } }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white.opacity(currentPage == 0 ? 0.2 : 0.8))
                    }
                    //
                    .padding(.leading, 70)
                    .disabled(currentPage == 0)

                    Spacer()

                    Button(action: {
                        withAnimation { if currentPage < 1 { currentPage += 1 } }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white.opacity(currentPage == 1 ? 0.2 : 0.8))
                    }
                    .padding(.trailing, 70)
                    .disabled(currentPage == 1)
                }
            }

            // STATIC BUTTON (No Blink)
            if !showDossier {
                BeigeGameButton(
                    title: currentPage == 0 ? "عرقه" : "قلعة",
                    isDisabled: currentPage == 1
                ) {
                    if currentPage == 0 {
                        withAnimation(.easeInOut(duration: 0.2)) { showDossier = true }
                    }
                }
                .overlay(
                    Group {
                        if currentPage == 1 {
                            Image("caution tape")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 2000)
                                .rotationEffect(.degrees(-34))
                                .offset(x: 123, y: 40) // MOVED TO RIGHT AND BOTTOM
                                .allowsHitTesting(false)
                                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 15)
                        }
                    }
                )
            }

            if showDossier && currentPage == 0 {
                DossierOverlay(isPresented: $showDossier)
            }
        }
        .onAppear { setupGalleryPlayers() }
        .onChange(of: currentPage) { newValue in handlePlayback(for: newValue) }
    }

    private func setupGalleryPlayers() {
        player2 = createAndLoopPlayer(name: "v2")
        player3 = createAndLoopPlayer(name: "v3")
        player2.play()
    }

    private func handlePlayback(for page: Int) {
        if page == 0 {
            player3.pause()
            player2.seek(to: .zero)
            player2.play()
        } else {
            player2.pause()
            player3.seek(to: .zero)
            player3.play()
        }
    }

    private func createAndLoopPlayer(name: String) -> AVPlayer {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mov") ??
                        Bundle.main.url(forResource: "v", withExtension: "mp4") else { return AVPlayer() }
        let player = AVPlayer(url: url)
        player.isMuted = true
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }
        return player
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

struct BeigeGameButton: View {
    let title: String
    let isDisabled: Bool
    let action: () -> Void
    
    private let darkRed = Color(red: 0.5, green: 0.1, blue: 0.1)
    private let beige = Color(red: 0.96, green: 0.91, blue: 0.82)
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 42, weight: .black, design: .serif))
                .foregroundColor(darkRed)
                .padding(.horizontal, 70)
                .padding(.vertical, 30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(beige)
                        .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(darkRed, lineWidth: 5)
                )
        }
        .buttonStyle(SolidInstantButtonStyle())
        .disabled(isDisabled)
    }
}

struct DossierOverlay: View {
    @Binding var isPresented: Bool
    
    private let staticText = """
    قبل إغلاق مستشفى عرقه،
    كان فيه جناح لم يُغلق رسميًا.
    الجناح رقم 13.
    المرضى فيه ما كانوا يُسجَّلون بأسماء.
    كانوا يُسجَّلون بأرقام.
    آخر ملاحظة محفوظة في السجلات تقول:
    """
    
    private let animatedTextGoal = "“المرضى لم يخرجوا…\nهم بقوا هنا.”"
    
    @State private var displayedAnimatedText = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            
            HStack(spacing: 80) {
                Image("paper")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250)
                
                VStack(alignment: .trailing, spacing: 0) {
                    Text(staticText)
                        .font(.system(size: 19, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.trailing)
                        .lineSpacing(10)
                    
                    Text(displayedAnimatedText)
                        .font(.system(size: 19, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.trailing)
                        .lineSpacing(10)
                }
                .frame(width: 400, alignment: .trailing)
                .onAppear {
                    startTypingAnimation()
                }
            }
            .padding(.trailing, 40)
            .padding(.bottom, 80)
            
            VStack {
                Spacer()
                Button(action: {
                    print("Game Started!")
                }) {
                    Text("العب")
                        .font(.system(size: 32, weight: .black, design: .serif))
                        .foregroundColor(.white)
                        .padding(.horizontal, 90)
                        .padding(.vertical, 22)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(red: 0.7, green: 0.1, blue: 0.1))
                        )
                        .shadow(radius: 8)
                }
                .buttonStyle(SolidInstantButtonStyle())
                .padding(.bottom, 50)
            }
            
            VStack {
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) { isPresented = false }
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 45))
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    Spacer()
                }
                Spacer()
            }
        }
        .transition(.opacity)
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
