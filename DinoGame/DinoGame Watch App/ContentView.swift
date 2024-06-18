//
//  ContentView.swift
//  DinoGame Watch App
//
//  Created by Sachin Agrawal on 6/14/24.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @State private var dinoY: CGFloat = 0
    @State private var obstacleX: CGFloat = WKInterfaceDevice.current().screenBounds.width
    @State private var velocityY: CGFloat = 0
    @State private var isJumping: Bool = false
    @State private var gameOver: Bool = false
    @State private var obstacleSpeed: CGFloat = 5.0
    @State private var score: Int = 0
    @State private var highScore: Int = UserDefaults.standard.integer(forKey: "highScore")
    @State private var obstacleImage: String = "cactus1"
    @State private var dinoImage: String = "trex-frame_1"
    @State private var dinoFrame: Int = 1
    @State private var showPterodactyl: Bool = false
    @State private var pterodactylHeight: CGFloat = 0
    @State private var pterodactylImage: String = "bird-frame_1"
    @State private var pterodactylFrame: Int = 1
    @State private var line1X: CGFloat = WKInterfaceDevice.current().screenBounds.width * 3 / 4
    @State private var line2X: CGFloat = WKInterfaceDevice.current().screenBounds.width / 4 - 50
    @State private var cloudX: CGFloat = WKInterfaceDevice.current().screenBounds.width
    @State private var crownRotation: Double = 0

    let gravity: CGFloat = 0.8
    let jumpVelocity: CGFloat = -10.0
    let dinoWidth: CGFloat = 20.0
    let dinoHeight: CGFloat = 20.0
    let obstacleWidth: CGFloat = 20.0
    let obstacleHeight: CGFloat = 20.0
    let groundHeight: CGFloat = 50.0
    let frameRate: CGFloat = 0.02
    let speedIncrement: CGFloat = 0.05
    let initialDelay: TimeInterval = 2.0
    let obstacleImages: [String] = ["cactus1", "cactus2", "cactus3"]
    let pterodactylImages: [String] = ["bird-frame_1", "bird-frame_2"]
    
    var body: some View {
        ZStack {
            // Night sky background
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.063, green: 0.122, blue: 0.2), Color(red: 0.271, green: 0.471, blue: 0.729)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
                .frame(width: WKInterfaceDevice.current().screenBounds.width, height: WKInterfaceDevice.current().screenBounds.height)
            
            // Moon image
            Image("moon")
                .resizable()
                .frame(width: 20, height: 20)
                .offset(x: WKInterfaceDevice.current().screenBounds.width / 2 - 30, y: -WKInterfaceDevice.current().screenBounds.height / 2 + 40)
            
            // Cloud
            Image("cloud")
                .resizable()
                .frame(width: 30, height: 22)
                .offset(x: cloudX, y: -WKInterfaceDevice.current().screenBounds.height / 2 + 70)
            
            // Ground
            VStack {
                Spacer()
                LinearGradient(gradient: Gradient(colors: [Color(red: 0.89, green: 0.729, blue: 0.125), Color(red: 0.439, green: 0.349, blue: 0.016)]), startPoint: .top, endPoint: .bottom)
                    .frame(height: groundHeight)
                    .overlay(
                        Rectangle()
                            .foregroundColor(.white)
                            .frame(height: 2)
                            .offset(y: -groundHeight / 2 + 1)
                    )
            }
            
            // Horizontal lines
            Rectangle()
                .frame(width: WKInterfaceDevice.current().screenBounds.width / 4, height: 2)
                .foregroundColor(.white)
                .offset(x: line1X, y: WKInterfaceDevice.current().screenBounds.height / 2 - groundHeight / 2)
            
            Rectangle()
                .frame(width: WKInterfaceDevice.current().screenBounds.width / 4, height: 2)
                .foregroundColor(.white)
                .offset(x: line2X, y: WKInterfaceDevice.current().screenBounds.height / 2 - groundHeight / 2 - 10)

            // Score displays
            VStack(alignment: .leading) {
                Text("Score: \(score)")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .alignmentGuide(.leading) { d in d[.leading] }
                
                Text("High Score: \(highScore)")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.top, 1)
                
                Text("ⓒ Sachin Agrawal 2024")
                    .font(.system(size: 6))
                    .foregroundColor(.white)
                    .padding(.top, 1)
            }
            .alignmentGuide(.top) { d in d[.top] }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // Dinosaur
            Image(dinoImage)
                .resizable()
                .frame(width: 40, height: 40)
                .offset(x: -WKInterfaceDevice.current().screenBounds.width / 4, y: dinoY + WKInterfaceDevice.current().screenBounds.height / 2 - 70)
            
            // Cactus or pterodactyl
            if showPterodactyl {
                Image(pterodactylImage)
                    .resizable()
                    .frame(width: 33, height: 40)
                    .offset(x: obstacleX, y: pterodactylHeight + WKInterfaceDevice.current().screenBounds.height / 2 - 70)
            } else {
                Image(obstacleImage)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .offset(x: obstacleX, y: WKInterfaceDevice.current().screenBounds.height / 2 - 70)
            }
        }
        .onTapGesture {
            jump()
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let horizontalTranslation = value.translation.height
                    if horizontalTranslation < 0 {
                        jump()
                    }
                }
        )
        .focusable()
        .digitalCrownRotation(detent: $crownRotation, from: 0.0, through: 1.0, by: 1.0, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: false) { crownEvent in
            if crownEvent.velocity != 0.0 {
                jump()
            }
        }
        .onAppear {
            startGame()
        }
        .alert(isPresented: $gameOver) {
            Alert(title: Text("Game Over"), message: Text("Score: \(score)"), dismissButton: .default(Text("Restart"), action: {
                resetGame()
            }))
        }
    }
    
    func startGame() {
        // Start game timers
        startObstacleSpawnTimer()
        startAnimationTimers()
        startJumpingTimer()
    }
    
    func startObstacleSpawnTimer() {
        // Schedule obstacle spawning after initial delay
        Timer.scheduledTimer(withTimeInterval: initialDelay, repeats: false) { _ in
            Timer.scheduledTimer(withTimeInterval: TimeInterval(frameRate), repeats: true) { timer in
                if !gameOver {
                    updateGame()
                } else {
                    timer.invalidate()
                }
            }
        }
    }
    
    func startAnimationTimers() {
        // Animation timer for dinosaur running
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !gameOver && !isJumping {
                dinoFrame = dinoFrame == 1 ? 2 : 1
                dinoImage = "trex-frame_\(dinoFrame)"
            }
            if gameOver {
                timer.invalidate()
            }
        }
        
        // And pterodactyl flying
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            if !gameOver && showPterodactyl {
                pterodactylFrame = pterodactylFrame == 1 ? 2 : 1
                pterodactylImage = "bird-frame_\(pterodactylFrame)"
            }
            if gameOver {
                timer.invalidate()
            }
        }
    }
    
    func startJumpingTimer() {
        // Allow jumps to be detected without a delay
        Timer.scheduledTimer(withTimeInterval: TimeInterval(frameRate), repeats: true) { timer in
            if !gameOver {
                handleJumps()
                moveLinesAndCloud()
            } else {
                timer.invalidate()
            }
        }
    }
    
    func handleJumps() {
        // Handle dinosaur jumping and falling
        if isJumping {
            dinoY += velocityY
            velocityY += gravity
            if dinoY >= 0 {
                dinoY = 0
                isJumping = false
                dinoImage = "trex-frame_1"
            }
        }
    }
    
    func moveLinesAndCloud() {
        // Move lines
        line1X -= obstacleSpeed
        line2X -= obstacleSpeed

        // Reset lines when they move off-screen
        if line1X < -WKInterfaceDevice.current().screenBounds.width / 2 {
            line1X = WKInterfaceDevice.current().screenBounds.width
        }
        if line2X < -WKInterfaceDevice.current().screenBounds.width / 2 {
            line2X = WKInterfaceDevice.current().screenBounds.width
        }

        // Move cloud at half the speed
        cloudX -= obstacleSpeed / 2

        // Reset cloud when it moves off-screen
        if cloudX < -WKInterfaceDevice.current().screenBounds.width / 2 {
            cloudX = WKInterfaceDevice.current().screenBounds.width
        }
    }
    
    func updateGame() {
        // Move obstacle
        obstacleX -= obstacleSpeed
        if obstacleX < -WKInterfaceDevice.current().screenBounds.width / 2 {
            obstacleX = WKInterfaceDevice.current().screenBounds.width
            if score > 10 && !showPterodactyl && Bool.random() {
                showPterodactyl = true
                pterodactylHeight = Bool.random() ? 0 : -40
                obstacleImage = pterodactylImages.randomElement()!
            } else {
                showPterodactyl = false
                obstacleImage = obstacleImages.randomElement()!
            }
            score += 1
            obstacleSpeed += speedIncrement
        }
        
        // Check for collision
        if showPterodactyl {
            if pterodactylHeight == 0 {
                if abs(obstacleX + WKInterfaceDevice.current().screenBounds.width / 4) < (dinoWidth + 20) / 2 && dinoY >= -dinoHeight {
                    endGame()
                }
            } else if pterodactylHeight == -40 {
                if abs(obstacleX + WKInterfaceDevice.current().screenBounds.width / 4) < (dinoWidth + 20) / 2 && dinoY < -30 {
                    endGame()
                }
            }
        } else {
            if abs(obstacleX + WKInterfaceDevice.current().screenBounds.width / 4) < (dinoWidth + obstacleWidth) / 2 && dinoY >= -dinoHeight {
                endGame()
            }
        }
    }
    
    func resetGame() {
        dinoY = 0
        obstacleX = WKInterfaceDevice.current().screenBounds.width
        velocityY = 0
        isJumping = false
        gameOver = false
        obstacleSpeed = 5.0
        score = 0
        showPterodactyl = false
        obstacleImage = obstacleImages.randomElement()!
        dinoImage = "trex-frame_1"
        line1X = WKInterfaceDevice.current().screenBounds.width * 3 / 4
        line2X = WKInterfaceDevice.current().screenBounds.width / 4 - 50
        cloudX = WKInterfaceDevice.current().screenBounds.width
        WKInterfaceDevice.current().play(.start)
        startObstacleSpawnTimer()
        startAnimationTimers()
        startJumpingTimer()
    }
    
    func endGame() {
        gameOver = true
        WKInterfaceDevice.current().play(.failure)
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "highScore")
        }
    }
    
    func jump() {
        if !isJumping && !gameOver {
            isJumping = true
            velocityY = jumpVelocity
            dinoImage = "trex"
            WKInterfaceDevice.current().play(.click)
        }
    }
}

#Preview {
    ContentView()
}
