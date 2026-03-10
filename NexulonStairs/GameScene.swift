import SpriteKit

class GameScene: SKScene {

    // MARK: - Constants
    private let stairWidth: CGFloat = 60
    private let stairHeight: CGFloat = 16
    private let stairGap: CGFloat = 55
    private let playerSize: CGFloat = 20
    // Fire tuned so player has ~2 seconds of breathing room per stair
    // stairGap (55) / initialFireSpeed (27.5) = 2.0 seconds per stair
    private let initialFireSpeed: CGFloat = 27.5
    private let maxFireSpeed: CGFloat = 110
    private let fireAcceleration: CGFloat = 0.4

    // MARK: - Nodes
    private var player: SKShapeNode!
    private var fireNode: SKShapeNode!
    private var fireEmitter: SKNode!
    private var scoreLabel: SKLabelNode!
    private var bestLabel: SKLabelNode!
    private var cameraNode: SKCameraNode!

    // MARK: - State
    private var stairs: [SKShapeNode] = []
    private var currentStairIndex = 0
    private var score = 0
    private var isGameOver = false
    private var fireYPosition: CGFloat = 0
    private var fireSpeed: CGFloat = 27.5
    private var previousHighScore = 0
    private var isNewBest = false
    private var lastUpdateTime: TimeInterval = 0
    private var playerOnLeft = true
    private var highestStairY: CGFloat = 0
    private var cameraTargetY: CGFloat = 0

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)

        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)

        fireSpeed = initialFireSpeed
        previousHighScore = UserDefaults.standard.integer(forKey: "highScore")
        setupPlayer()
        setupFire()
        setupUI()
        generateInitialStairs()

        // Position camera
        cameraTargetY = player.position.y + size.height * 0.15
        cameraNode.position = CGPoint(x: size.width / 2, y: cameraTargetY)
    }

    // MARK: - Setup
    private func setupPlayer() {
        player = SKShapeNode(rectOf: CGSize(width: playerSize, height: playerSize), cornerRadius: 4)
        player.fillColor = SKColor(red: 0.3, green: 0.9, blue: 1.0, alpha: 1.0)
        player.strokeColor = .white
        player.lineWidth = 1.5
        player.zPosition = 10

        let startX = size.width / 2 - stairWidth / 2
        player.position = CGPoint(x: startX, y: stairHeight + playerSize / 2 + 5)
        playerOnLeft = true
        addChild(player)

        // Glow effect
        let glow = SKShapeNode(rectOf: CGSize(width: playerSize + 8, height: playerSize + 8), cornerRadius: 6)
        glow.fillColor = SKColor(red: 0.3, green: 0.9, blue: 1.0, alpha: 0.2)
        glow.strokeColor = .clear
        glow.zPosition = -1
        player.addChild(glow)

        let pulseOut = SKAction.scale(to: 1.3, duration: 0.6)
        let pulseIn = SKAction.scale(to: 1.0, duration: 0.6)
        glow.run(SKAction.repeatForever(SKAction.sequence([pulseOut, pulseIn])))
    }

    private func setupFire() {
        fireYPosition = -50

        fireNode = SKShapeNode(rectOf: CGSize(width: size.width * 3, height: 200))
        fireNode.fillColor = .clear
        fireNode.strokeColor = .clear
        fireNode.position = CGPoint(x: size.width / 2, y: fireYPosition)
        fireNode.zPosition = 5
        addChild(fireNode)

        // Build fire visuals from layered rectangles
        let colors: [(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)] = [
            (1.0, 0.1, 0.0, 0.9),  // deep red base
            (1.0, 0.3, 0.0, 0.7),  // orange
            (1.0, 0.5, 0.0, 0.5),  // light orange
            (1.0, 0.7, 0.1, 0.3),  // yellow glow
        ]

        for (i, c) in colors.enumerated() {
            let layerHeight: CGFloat = 200 - CGFloat(i) * 40
            let layer = SKShapeNode(rectOf: CGSize(width: size.width * 3, height: layerHeight))
            layer.fillColor = SKColor(red: c.r, green: c.g, blue: c.b, alpha: c.a)
            layer.strokeColor = .clear
            layer.position = CGPoint(x: 0, y: -CGFloat(i) * 10)
            layer.zPosition = CGFloat(i)
            fireNode.addChild(layer)

            // Flicker animation
            let moveUp = SKAction.moveBy(x: 0, y: CGFloat.random(in: 5...15), duration: Double.random(in: 0.3...0.6))
            let moveDown = SKAction.moveBy(x: 0, y: -CGFloat.random(in: 5...15), duration: Double.random(in: 0.3...0.6))
            layer.run(SKAction.repeatForever(SKAction.sequence([moveUp, moveDown])))
        }

        // Fire particles (simple circles rising)
        let spawnParticle = SKAction.run { [weak self] in
            self?.spawnFireParticle()
        }
        let wait = SKAction.wait(forDuration: 0.05)
        run(SKAction.repeatForever(SKAction.sequence([spawnParticle, wait])))
    }

    private func spawnFireParticle() {
        let particleSize = CGFloat.random(in: 3...8)
        let particle = SKShapeNode(circleOfRadius: particleSize)
        let brightness = CGFloat.random(in: 0.5...1.0)
        particle.fillColor = SKColor(red: 1.0, green: brightness * 0.6, blue: 0.0, alpha: 0.8)
        particle.strokeColor = .clear
        particle.zPosition = 6

        let xPos = CGFloat.random(in: -size.width...size.width * 2)
        particle.position = CGPoint(x: xPos, y: fireYPosition + CGFloat.random(in: 60...120))
        addChild(particle)

        let rise = SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: 30...80), duration: Double.random(in: 0.4...0.8))
        let fade = SKAction.fadeOut(withDuration: 0.5)
        let group = SKAction.group([rise, fade])
        particle.run(SKAction.sequence([group, SKAction.removeFromParent()]))
    }

    private func setupUI() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "0"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = .white
        scoreLabel.zPosition = 100
        scoreLabel.position = CGPoint(x: 0, y: size.height * 0.38)
        cameraNode.addChild(scoreLabel)

        // Personal best tracker in top-right corner
        bestLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        bestLabel.text = "BEST: \(previousHighScore)"
        bestLabel.fontSize = 16
        bestLabel.fontColor = SKColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 0.7)
        bestLabel.horizontalAlignmentMode = .right
        bestLabel.zPosition = 100
        bestLabel.position = CGPoint(x: size.width / 2 - 20, y: size.height * 0.38)
        cameraNode.addChild(bestLabel)
    }

    // MARK: - Stair Generation
    private func generateInitialStairs() {
        // Ground platform
        let ground = SKShapeNode(rectOf: CGSize(width: size.width, height: stairHeight * 2))
        ground.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)
        ground.strokeColor = SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)
        ground.lineWidth = 1
        ground.position = CGPoint(x: size.width / 2, y: stairHeight)
        ground.zPosition = 1
        addChild(ground)

        // Generate stairs going up
        var lastLeft = true

        for i in 0..<50 {
            let y = CGFloat(i + 1) * stairGap + stairHeight
            let goLeft = !lastLeft  // alternate sides
            let x: CGFloat
            if goLeft {
                x = size.width / 2 - stairWidth / 2 - CGFloat.random(in: 20...50)
            } else {
                x = size.width / 2 + stairWidth / 2 + CGFloat.random(in: 20...50)
            }

            let stair = createStair(at: CGPoint(x: x, y: y), index: i)
            stairs.append(stair)
            addChild(stair)

            lastLeft = goLeft
            highestStairY = y
        }
    }

    private func createStair(at position: CGPoint, index: Int) -> SKShapeNode {
        let stair = SKShapeNode(rectOf: CGSize(width: stairWidth, height: stairHeight), cornerRadius: 3)

        // Color varies slightly for visual interest
        let hue = CGFloat(index % 10) / 10.0
        stair.fillColor = SKColor(hue: hue, saturation: 0.3, brightness: 0.6, alpha: 1.0)
        stair.strokeColor = SKColor(hue: hue, saturation: 0.3, brightness: 0.8, alpha: 1.0)
        stair.lineWidth = 1
        stair.position = position
        stair.zPosition = 2
        stair.name = "stair_\(index)"

        return stair
    }

    private func generateMoreStairs() {
        guard let lastStair = stairs.last else { return }
        let lastY = lastStair.position.y
        let lastX = lastStair.position.x
        let isLastLeft = lastX < size.width / 2

        let startIndex = stairs.count
        for i in 0..<20 {
            let y = lastY + CGFloat(i + 1) * stairGap
            let goLeft = (i % 2 == 0) ? !isLastLeft : isLastLeft
            let x: CGFloat
            if goLeft {
                x = size.width / 2 - stairWidth / 2 - CGFloat.random(in: 20...50)
            } else {
                x = size.width / 2 + stairWidth / 2 + CGFloat.random(in: 20...50)
            }

            let stair = createStair(at: CGPoint(x: x, y: y), index: startIndex + i)
            stairs.append(stair)
            addChild(stair)
            highestStairY = y
        }
    }

    // MARK: - Input
    private var canRestart = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            if canRestart {
                restartGame()
            }
            return
        }

        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        let tappedLeft = location.x < size.width / 2
        movePlayerToNextStair(goLeft: tappedLeft)
    }

    private func movePlayerToNextStair(goLeft: Bool) {
        let nextIndex = currentStairIndex + 1
        guard nextIndex < stairs.count else { return }

        let targetStair = stairs[nextIndex]
        let targetX = targetStair.position.x
        let targetY = targetStair.position.y + stairHeight / 2 + playerSize / 2

        // Check if player tapped the correct direction
        let stairIsLeft = targetX < size.width / 2
        if goLeft != stairIsLeft {
            // Wrong direction — player falls!
            gameOver()
            return
        }

        currentStairIndex = nextIndex
        score = nextIndex

        // Animate player jump
        let midY = max(player.position.y, targetY) + 30
        let duration: TimeInterval = 0.15

        let path = CGMutablePath()
        path.move(to: player.position)
        path.addQuadCurve(to: CGPoint(x: targetX, y: targetY),
                          control: CGPoint(x: (player.position.x + targetX) / 2, y: midY))

        let moveAction = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
        moveAction.timingMode = .easeOut

        player.run(moveAction) { [weak self] in
            self?.onPlayerLanded()
        }

        // Update score
        scoreLabel.text = "\(score)"

        // Check for new personal best mid-game
        if score > previousHighScore && !isNewBest && previousHighScore > 0 {
            isNewBest = true
            showNewBestCelebration()
        }

        // Stair hit effect
        let scaleUp = SKAction.scaleX(to: 1.15, duration: 0.05)
        let scaleDown = SKAction.scaleX(to: 1.0, duration: 0.1)
        targetStair.run(SKAction.sequence([scaleUp, scaleDown]))

        // Speed up fire over time
        fireSpeed = min(maxFireSpeed, initialFireSpeed + CGFloat(score) * fireAcceleration)
    }

    private func showNewBestCelebration() {
        // Flash the best label
        bestLabel.text = "NEW BEST!"
        bestLabel.fontColor = SKColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0)
        bestLabel.fontSize = 20

        // Big "NEW BEST!" banner in center
        let banner = SKLabelNode(fontNamed: "AvenirNext-Bold")
        banner.text = "NEW BEST!"
        banner.fontSize = 32
        banner.fontColor = SKColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0)
        banner.zPosition = 100
        banner.position = CGPoint(x: 0, y: size.height * 0.2)
        cameraNode.addChild(banner)

        let scaleUp = SKAction.scale(to: 1.4, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        banner.run(SKAction.sequence([scaleUp, scaleDown, SKAction.wait(forDuration: 0.5), fadeOut, SKAction.removeFromParent()]))

        // Sparkle particles around player
        for _ in 0..<12 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            spark.fillColor = SKColor(red: 1.0, green: CGFloat.random(in: 0.7...1.0), blue: 0.2, alpha: 1.0)
            spark.strokeColor = .clear
            spark.zPosition = 15
            spark.position = player.position
            addChild(spark)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 40...100)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist
            let move = SKAction.moveBy(x: dx, y: dy, duration: Double.random(in: 0.4...0.7))
            let fade = SKAction.fadeOut(withDuration: 0.5)
            spark.run(SKAction.sequence([SKAction.group([move, fade]), SKAction.removeFromParent()]))
        }
    }

    private func onPlayerLanded() {
        // Generate more stairs if getting close to the top
        if CGFloat(currentStairIndex) > CGFloat(stairs.count) - 15 {
            generateMoreStairs()
        }
    }

    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }

        let dt: CGFloat
        if lastUpdateTime == 0 {
            dt = 1.0 / 60.0
        } else {
            dt = CGFloat(currentTime - lastUpdateTime)
        }
        lastUpdateTime = currentTime

        // Move fire upward
        fireYPosition += fireSpeed * dt
        fireNode.position.y = fireYPosition

        // Camera follows player smoothly
        let targetCamY = player.position.y + size.height * 0.15
        cameraTargetY += (targetCamY - cameraTargetY) * 0.1
        cameraNode.position = CGPoint(x: size.width / 2, y: cameraTargetY)

        // Check if fire reached the player
        if fireYPosition + 80 > player.position.y {
            gameOver()
        }

        // Remove stairs that are below the fire
        stairs.removeAll { stair in
            if stair.position.y < fireYPosition - 100 {
                stair.removeFromParent()
                return true
            }
            return false
        }
    }

    // MARK: - Game Over
    private enum DeathType {
        case fell       // tapped wrong direction
        case consumed   // lava caught up
    }

    private func gameOver() {
        guard !isGameOver else { return }
        isGameOver = true

        // Save high score
        let highScore = UserDefaults.standard.integer(forKey: "highScore")
        if score > highScore {
            UserDefaults.standard.set(score, forKey: "highScore")
            if !isNewBest && previousHighScore > 0 {
                isNewBest = true
            }
        }

        // Hide HUD during death animation
        scoreLabel.isHidden = true
        bestLabel.isHidden = true

        // Determine death type
        let deathType: DeathType = (fireYPosition + 80 > player.position.y) ? .consumed : .fell

        // Step 1: Player death animation
        switch deathType {
        case .fell:
            // Player tumbles off to the side and falls down
            let fallDirection: CGFloat = Bool.random() ? 1.0 : -1.0
            let spin = SKAction.rotate(byAngle: fallDirection * .pi * 4, duration: 0.8)
            let fall = SKAction.moveBy(x: fallDirection * 60, y: -300, duration: 0.8)
            fall.timingMode = .easeIn
            let shrink = SKAction.scale(to: 0.3, duration: 0.8)
            player.run(SKAction.group([spin, fall, shrink]))

        case .consumed:
            // Player gets swallowed — sinks into lava with a flash
            let sink = SKAction.moveBy(x: 0, y: -40, duration: 0.3)
            let fade = SKAction.fadeOut(withDuration: 0.3)
            player.run(SKAction.group([sink, fade]))
        }

        // Step 2: After brief pause, lava rushes up and fills the entire screen
        let deathPause: TimeInterval = (deathType == .fell) ? 0.5 : 0.2
        run(SKAction.sequence([
            SKAction.wait(forDuration: deathPause),
            SKAction.run { [weak self] in
                self?.lavaFillScreen()
            }
        ]))
    }

    private func lavaFillScreen() {
        // Create a massive lava overlay that rises from current fire position to fill the screen
        let camY = cameraNode.position.y
        let screenTop = camY + size.height / 2
        let lavaStartY = fireYPosition + 100

        // Giant lava wall that will rise to cover everything
        let lavaHeight = size.height * 2
        let lavaWall = SKShapeNode(rectOf: CGSize(width: size.width * 3, height: lavaHeight))
        lavaWall.fillColor = SKColor(red: 1.0, green: 0.15, blue: 0.0, alpha: 0.95)
        lavaWall.strokeColor = .clear
        lavaWall.zPosition = 80
        lavaWall.position = CGPoint(x: size.width / 2, y: lavaStartY - lavaHeight / 2)
        addChild(lavaWall)

        // Orange glow layer on top
        let glowLayer = SKShapeNode(rectOf: CGSize(width: size.width * 3, height: lavaHeight))
        glowLayer.fillColor = SKColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 0.6)
        glowLayer.strokeColor = .clear
        glowLayer.zPosition = 81
        glowLayer.position = CGPoint(x: size.width / 2, y: lavaStartY - lavaHeight / 2 + 30)
        addChild(glowLayer)

        // Yellow hot top edge
        let hotEdge = SKShapeNode(rectOf: CGSize(width: size.width * 3, height: 40))
        hotEdge.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.1, alpha: 0.8)
        hotEdge.strokeColor = .clear
        hotEdge.zPosition = 82
        hotEdge.position = CGPoint(x: size.width / 2, y: lavaStartY)
        addChild(hotEdge)

        // Calculate how far the lava needs to rise
        let distanceToFill = screenTop - lavaStartY + lavaHeight
        let riseDuration: TimeInterval = 1.0

        let riseAction = SKAction.moveBy(x: 0, y: distanceToFill, duration: riseDuration)
        riseAction.timingMode = .easeIn

        lavaWall.run(riseAction)
        glowLayer.run(SKAction.moveBy(x: 0, y: distanceToFill, duration: riseDuration))
        hotEdge.run(SKAction.moveBy(x: 0, y: distanceToFill, duration: riseDuration))

        // Spawn extra fire particles during the rush
        for i in 0..<20 {
            run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.05),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    for _ in 0..<3 {
                        let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...10))
                        spark.fillColor = SKColor(red: 1.0, green: CGFloat.random(in: 0.3...0.9), blue: 0.0, alpha: 1.0)
                        spark.strokeColor = .clear
                        spark.zPosition = 83
                        let xPos = CGFloat.random(in: 0...self.size.width)
                        spark.position = CGPoint(x: xPos, y: lavaStartY + CGFloat(i) * (distanceToFill / 20))
                        self.addChild(spark)

                        let rise = SKAction.moveBy(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: 40...120), duration: 0.6)
                        let fade = SKAction.fadeOut(withDuration: 0.4)
                        spark.run(SKAction.sequence([SKAction.group([rise, fade]), SKAction.removeFromParent()]))
                    }
                }
            ]))
        }

        // Step 3: Once lava fills the screen, show game over UI on top
        run(SKAction.sequence([
            SKAction.wait(forDuration: riseDuration + 0.3),
            SKAction.run { [weak self] in
                self?.showGameOverScreen()
            }
        ]))
    }

    private func showGameOverScreen() {
        // Dark overlay on top of lava for readability
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 3, height: size.height * 3))
        overlay.fillColor = SKColor(red: 0.1, green: 0.02, blue: 0.0, alpha: 0.0)
        overlay.strokeColor = .clear
        overlay.zPosition = 90
        overlay.position = .zero
        cameraNode.addChild(overlay)
        overlay.run(SKAction.customAction(withDuration: 0.6) { node, elapsed in
            let progress = elapsed / 0.6
            (node as? SKShapeNode)?.fillColor = SKColor(red: 0.1, green: 0.02, blue: 0.0, alpha: progress * 0.7)
        })

        // All game over labels start invisible and fade in
        let fadeInDelay: TimeInterval = 0.3

        // "GAME OVER"
        let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 44
        gameOverLabel.fontColor = .white
        gameOverLabel.alpha = 0
        gameOverLabel.zPosition = 100
        gameOverLabel.position = CGPoint(x: 0, y: 80)
        cameraNode.addChild(gameOverLabel)

        // "You climbed X stairs"
        let climbedLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        climbedLabel.text = "You climbed \(score) stairs"
        climbedLabel.fontSize = 24
        climbedLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.7, alpha: 1.0)
        climbedLabel.alpha = 0
        climbedLabel.zPosition = 100
        climbedLabel.position = CGPoint(x: 0, y: 30)
        cameraNode.addChild(climbedLabel)

        // Score number (big)
        let scoreNumber = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreNumber.text = "\(score)"
        scoreNumber.fontSize = 72
        scoreNumber.fontColor = SKColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0)
        scoreNumber.alpha = 0
        scoreNumber.zPosition = 100
        scoreNumber.position = CGPoint(x: 0, y: -40)
        cameraNode.addChild(scoreNumber)

        // High score line
        let bestScore = UserDefaults.standard.integer(forKey: "highScore")
        let highScoreLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        if isNewBest {
            highScoreLabel.text = "NEW PERSONAL BEST!"
            highScoreLabel.fontColor = SKColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0)
            highScoreLabel.fontSize = 22
        } else {
            highScoreLabel.text = "Personal Best: \(bestScore)"
            highScoreLabel.fontColor = SKColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.8)
            highScoreLabel.fontSize = 20
        }
        highScoreLabel.alpha = 0
        highScoreLabel.zPosition = 100
        highScoreLabel.position = CGPoint(x: 0, y: -100)
        cameraNode.addChild(highScoreLabel)

        // "TAP TO RESTART"
        let tapRestart = SKLabelNode(fontNamed: "AvenirNext-Medium")
        tapRestart.text = "TAP TO RESTART"
        tapRestart.fontSize = 20
        tapRestart.fontColor = .white
        tapRestart.alpha = 0
        tapRestart.zPosition = 100
        tapRestart.position = CGPoint(x: 0, y: -160)
        cameraNode.addChild(tapRestart)

        // Fade in sequence — staggered for dramatic effect
        gameOverLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: fadeInDelay),
            SKAction.fadeIn(withDuration: 0.4)
        ]))

        climbedLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: fadeInDelay + 0.2),
            SKAction.fadeIn(withDuration: 0.4)
        ]))

        scoreNumber.run(SKAction.sequence([
            SKAction.wait(forDuration: fadeInDelay + 0.4),
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.sequence([SKAction.scale(to: 1.3, duration: 0.15), SKAction.scale(to: 1.0, duration: 0.15)])
            ])
        ]))

        highScoreLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: fadeInDelay + 0.7),
            SKAction.fadeIn(withDuration: 0.4)
        ]))

        if isNewBest {
            highScoreLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: fadeInDelay + 0.7),
                SKAction.repeatForever(SKAction.sequence([
                    SKAction.scale(to: 1.1, duration: 0.5),
                    SKAction.scale(to: 1.0, duration: 0.5)
                ]))
            ]))
        }

        tapRestart.run(SKAction.sequence([
            SKAction.wait(forDuration: fadeInDelay + 1.0),
            SKAction.fadeIn(withDuration: 0.4),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.7),
                SKAction.fadeAlpha(to: 1.0, duration: 0.7)
            ]))
        ]))

        // Allow restart after everything is shown
        run(SKAction.sequence([
            SKAction.wait(forDuration: fadeInDelay + 1.2),
            SKAction.run { [weak self] in
                self?.canRestart = true
            }
        ]))
    }

    private func restartGame() {
        let newScene = GameScene(size: self.size)
        newScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 0.3)
        view?.presentScene(newScene, transition: transition)
    }
}
