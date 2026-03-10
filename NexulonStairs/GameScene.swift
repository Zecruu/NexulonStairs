import SpriteKit

class GameScene: SKScene {

    // MARK: - Constants
    private let stairWidth: CGFloat = 70
    private let stairHeight: CGFloat = 16
    private let stairGap: CGFloat = 55
    private let playerSize: CGFloat = 20
    // Fire tuned so player has ~2 seconds of breathing room per stair
    private let initialFireSpeed: CGFloat = 27.5
    private let maxFireSpeed: CGFloat = 110
    private let fireAcceleration: CGFloat = 0.4

    // 3-column layout positions (calculated in didMove)
    private var columnX: [CGFloat] = []  // [left, center, right]

    // MARK: - Nodes
    private var player: SKShapeNode!
    private var fireNode: SKShapeNode!
    private var scoreLabel: SKLabelNode!
    private var bestLabel: SKLabelNode!
    private var cameraNode: SKCameraNode!

    // MARK: - State
    private struct StairInfo {
        let node: SKShapeNode
        let column: Int  // 0=left, 1=center, 2=right
    }
    private var stairs: [StairInfo] = []
    private var currentStairIndex = -1  // -1 = on ground platform
    private var currentColumn = 1       // start in center
    private var score = 0
    private var isGameOver = false
    private var fireYPosition: CGFloat = 0
    private var fireSpeed: CGFloat = 27.5
    private var previousHighScore = 0
    private var isNewBest = false
    private var lastUpdateTime: TimeInterval = 0
    private var cameraTargetY: CGFloat = 0
    private var canRestart = false

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)

        // 3 columns evenly spaced
        let margin: CGFloat = 60
        let spacing = (size.width - margin * 2) / 2
        columnX = [
            margin,                    // left
            margin + spacing,          // center
            margin + spacing * 2       // right
        ]

        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)

        fireSpeed = initialFireSpeed
        fireYPosition = -300  // start fire well below player
        previousHighScore = UserDefaults.standard.integer(forKey: "highScore")

        setupPlayer()
        setupFire()
        setupUI()
        generateStairs(count: 50, startY: stairGap + stairHeight)

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
        player.position = CGPoint(x: columnX[1], y: stairHeight + playerSize / 2 + 5)
        addChild(player)

        // Glow
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
        fireNode = SKShapeNode(rectOf: CGSize(width: size.width * 3, height: 200))
        fireNode.fillColor = .clear
        fireNode.strokeColor = .clear
        fireNode.position = CGPoint(x: size.width / 2, y: fireYPosition)
        fireNode.zPosition = 5
        addChild(fireNode)

        let colors: [(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)] = [
            (1.0, 0.1, 0.0, 0.9),
            (1.0, 0.3, 0.0, 0.7),
            (1.0, 0.5, 0.0, 0.5),
            (1.0, 0.7, 0.1, 0.3),
        ]
        for (i, c) in colors.enumerated() {
            let layerHeight: CGFloat = 200 - CGFloat(i) * 40
            let layer = SKShapeNode(rectOf: CGSize(width: size.width * 3, height: layerHeight))
            layer.fillColor = SKColor(red: c.r, green: c.g, blue: c.b, alpha: c.a)
            layer.strokeColor = .clear
            layer.position = CGPoint(x: 0, y: -CGFloat(i) * 10)
            layer.zPosition = CGFloat(i)
            fireNode.addChild(layer)
            let moveUp = SKAction.moveBy(x: 0, y: CGFloat.random(in: 5...15), duration: Double.random(in: 0.3...0.6))
            let moveDown = SKAction.moveBy(x: 0, y: -CGFloat.random(in: 5...15), duration: Double.random(in: 0.3...0.6))
            layer.run(SKAction.repeatForever(SKAction.sequence([moveUp, moveDown])))
        }

        let spawnParticle = SKAction.run { [weak self] in self?.spawnFireParticle() }
        run(SKAction.repeatForever(SKAction.sequence([spawnParticle, SKAction.wait(forDuration: 0.05)])))
    }

    private func spawnFireParticle() {
        let sz = CGFloat.random(in: 3...8)
        let particle = SKShapeNode(circleOfRadius: sz)
        particle.fillColor = SKColor(red: 1.0, green: CGFloat.random(in: 0.3...0.6), blue: 0.0, alpha: 0.8)
        particle.strokeColor = .clear
        particle.zPosition = 6
        particle.position = CGPoint(x: CGFloat.random(in: -size.width...size.width * 2),
                                     y: fireYPosition + CGFloat.random(in: 60...120))
        addChild(particle)
        let rise = SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: 30...80), duration: Double.random(in: 0.4...0.8))
        let fade = SKAction.fadeOut(withDuration: 0.5)
        particle.run(SKAction.sequence([SKAction.group([rise, fade]), SKAction.removeFromParent()]))
    }

    private func setupUI() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "0"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = .white
        scoreLabel.zPosition = 100
        scoreLabel.position = CGPoint(x: 0, y: size.height * 0.38)
        cameraNode.addChild(scoreLabel)

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
    private func generateStairs(count: Int, startY: CGFloat) {
        let lastColumn = stairs.last?.column ?? currentColumn

        var prevCol = lastColumn
        for i in 0..<count {
            let y = startY + CGFloat(i) * stairGap

            // Pick a different column than the previous stair
            var possibleColumns = [0, 1, 2].filter { $0 != prevCol }
            let col = possibleColumns.randomElement()!

            let stair = createStair(at: CGPoint(x: columnX[col], y: y))
            addChild(stair)
            stairs.append(StairInfo(node: stair, column: col))
            prevCol = col
        }
    }

    private func createStair(at position: CGPoint) -> SKShapeNode {
        let stair = SKShapeNode(rectOf: CGSize(width: stairWidth, height: stairHeight), cornerRadius: 3)
        let hue = CGFloat.random(in: 0...1)
        stair.fillColor = SKColor(hue: hue, saturation: 0.3, brightness: 0.6, alpha: 1.0)
        stair.strokeColor = SKColor(hue: hue, saturation: 0.3, brightness: 0.8, alpha: 1.0)
        stair.lineWidth = 1
        stair.position = position
        stair.zPosition = 2
        return stair
    }

    // MARK: - Input
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            if canRestart { restartGame() }
            return
        }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Tap left half = go left, tap right half = go right
        let tappedLeft = location.x < size.width / 2
        movePlayer(tappedLeft: tappedLeft)
    }

    private func movePlayer(tappedLeft: Bool) {
        let nextIndex = currentStairIndex + 1
        guard nextIndex < stairs.count else { return }

        let nextStair = stairs[nextIndex]
        let nextCol = nextStair.column

        // Determine which direction the next stair is relative to current position
        let nextIsLeft = nextCol < currentColumn
        let nextIsRight = nextCol > currentColumn

        // Player tapped left but next stair is to the right (or vice versa) = wrong!
        if tappedLeft && nextIsRight {
            gameOver()
            return
        }
        if !tappedLeft && nextIsLeft {
            gameOver()
            return
        }

        // Correct tap — move player
        currentStairIndex = nextIndex
        currentColumn = nextCol
        score = nextIndex

        let targetX = columnX[nextCol]
        let targetY = nextStair.node.position.y + stairHeight / 2 + playerSize / 2

        // Arc jump animation
        let midY = max(player.position.y, targetY) + 30
        let path = CGMutablePath()
        path.move(to: player.position)
        path.addQuadCurve(to: CGPoint(x: targetX, y: targetY),
                          control: CGPoint(x: (player.position.x + targetX) / 2, y: midY))
        let moveAction = SKAction.follow(path, asOffset: false, orientToPath: false, duration: 0.15)
        moveAction.timingMode = .easeOut
        player.run(moveAction) { [weak self] in
            self?.onPlayerLanded()
        }

        scoreLabel.text = "\(score)"

        // New best check
        if score > previousHighScore && !isNewBest && previousHighScore > 0 {
            isNewBest = true
            showNewBestCelebration()
        }

        // Stair bounce effect
        let scaleUp = SKAction.scaleX(to: 1.15, duration: 0.05)
        let scaleDown = SKAction.scaleX(to: 1.0, duration: 0.1)
        nextStair.node.run(SKAction.sequence([scaleUp, scaleDown]))

        fireSpeed = min(maxFireSpeed, initialFireSpeed + CGFloat(score) * fireAcceleration)
    }

    private func showNewBestCelebration() {
        bestLabel.text = "NEW BEST!"
        bestLabel.fontColor = SKColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0)
        bestLabel.fontSize = 20

        let banner = SKLabelNode(fontNamed: "AvenirNext-Bold")
        banner.text = "NEW BEST!"
        banner.fontSize = 32
        banner.fontColor = SKColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0)
        banner.zPosition = 100
        banner.position = CGPoint(x: 0, y: size.height * 0.2)
        cameraNode.addChild(banner)
        banner.run(SKAction.sequence([
            SKAction.scale(to: 1.4, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.15),
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ]))

        for _ in 0..<12 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            spark.fillColor = SKColor(red: 1.0, green: CGFloat.random(in: 0.7...1.0), blue: 0.2, alpha: 1.0)
            spark.strokeColor = .clear
            spark.zPosition = 15
            spark.position = player.position
            addChild(spark)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 40...100)
            let move = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: Double.random(in: 0.4...0.7))
            let fade = SKAction.fadeOut(withDuration: 0.5)
            spark.run(SKAction.sequence([SKAction.group([move, fade]), SKAction.removeFromParent()]))
        }
    }

    private func onPlayerLanded() {
        if currentStairIndex > stairs.count - 15 {
            let lastY = stairs.last!.node.position.y
            generateStairs(count: 20, startY: lastY + stairGap)
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

        fireYPosition += fireSpeed * dt
        fireNode.position.y = fireYPosition

        let targetCamY = player.position.y + size.height * 0.15
        cameraTargetY += (targetCamY - cameraTargetY) * 0.1
        cameraNode.position = CGPoint(x: size.width / 2, y: cameraTargetY)

        // Fire death check — fire top visually is at fireYPosition + 100 (top of the fire graphic)
        if fireYPosition + 100 > player.position.y {
            gameOver()
        }

        // Clean up stairs below fire
        stairs.removeAll { info in
            if info.node.position.y < fireYPosition - 100 {
                info.node.removeFromParent()
                return true
            }
            return false
        }
    }

    // MARK: - Game Over
    private enum DeathType {
        case fell
        case consumed
    }

    private func gameOver() {
        guard !isGameOver else { return }
        isGameOver = true

        let highScore = UserDefaults.standard.integer(forKey: "highScore")
        if score > highScore {
            UserDefaults.standard.set(score, forKey: "highScore")
            if !isNewBest && previousHighScore > 0 { isNewBest = true }
        }

        scoreLabel.isHidden = true
        bestLabel.isHidden = true

        let deathType: DeathType = (fireYPosition + 100 > player.position.y) ? .consumed : .fell

        switch deathType {
        case .fell:
            let dir: CGFloat = Bool.random() ? 1.0 : -1.0
            let spin = SKAction.rotate(byAngle: dir * .pi * 4, duration: 0.8)
            let fall = SKAction.moveBy(x: dir * 60, y: -300, duration: 0.8)
            fall.timingMode = .easeIn
            player.run(SKAction.group([spin, fall, SKAction.scale(to: 0.3, duration: 0.8)]))
        case .consumed:
            player.run(SKAction.group([
                SKAction.moveBy(x: 0, y: -40, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]))
        }

        let deathPause: TimeInterval = (deathType == .fell) ? 0.5 : 0.2
        run(SKAction.sequence([
            SKAction.wait(forDuration: deathPause),
            SKAction.run { [weak self] in self?.lavaFillScreen() }
        ]))
    }

    private func lavaFillScreen() {
        let camY = cameraNode.position.y
        let screenTop = camY + size.height / 2
        let lavaStartY = fireYPosition + 100
        let lavaHeight = size.height * 2

        let lavaWall = SKShapeNode(rectOf: CGSize(width: size.width * 3, height: lavaHeight))
        lavaWall.fillColor = SKColor(red: 1.0, green: 0.15, blue: 0.0, alpha: 0.95)
        lavaWall.strokeColor = .clear
        lavaWall.zPosition = 80
        lavaWall.position = CGPoint(x: size.width / 2, y: lavaStartY - lavaHeight / 2)
        addChild(lavaWall)

        let glowLayer = SKShapeNode(rectOf: CGSize(width: size.width * 3, height: lavaHeight))
        glowLayer.fillColor = SKColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 0.6)
        glowLayer.strokeColor = .clear
        glowLayer.zPosition = 81
        glowLayer.position = CGPoint(x: size.width / 2, y: lavaStartY - lavaHeight / 2 + 30)
        addChild(glowLayer)

        let hotEdge = SKShapeNode(rectOf: CGSize(width: size.width * 3, height: 40))
        hotEdge.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.1, alpha: 0.8)
        hotEdge.strokeColor = .clear
        hotEdge.zPosition = 82
        hotEdge.position = CGPoint(x: size.width / 2, y: lavaStartY)
        addChild(hotEdge)

        let distanceToFill = screenTop - lavaStartY + lavaHeight
        let riseDuration: TimeInterval = 1.0
        let riseAction = SKAction.moveBy(x: 0, y: distanceToFill, duration: riseDuration)
        riseAction.timingMode = .easeIn

        lavaWall.run(riseAction)
        glowLayer.run(SKAction.moveBy(x: 0, y: distanceToFill, duration: riseDuration))
        hotEdge.run(SKAction.moveBy(x: 0, y: distanceToFill, duration: riseDuration))

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
                        spark.position = CGPoint(x: CGFloat.random(in: 0...self.size.width),
                                                  y: lavaStartY + CGFloat(i) * (distanceToFill / 20))
                        self.addChild(spark)
                        let rise = SKAction.moveBy(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: 40...120), duration: 0.6)
                        let fade = SKAction.fadeOut(withDuration: 0.4)
                        spark.run(SKAction.sequence([SKAction.group([rise, fade]), SKAction.removeFromParent()]))
                    }
                }
            ]))
        }

        run(SKAction.sequence([
            SKAction.wait(forDuration: riseDuration + 0.3),
            SKAction.run { [weak self] in self?.showGameOverScreen() }
        ]))
    }

    private func showGameOverScreen() {
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 3, height: size.height * 3))
        overlay.fillColor = SKColor(red: 0.1, green: 0.02, blue: 0.0, alpha: 0.0)
        overlay.strokeColor = .clear
        overlay.zPosition = 90
        overlay.position = .zero
        cameraNode.addChild(overlay)
        overlay.run(SKAction.customAction(withDuration: 0.6) { node, elapsed in
            (node as? SKShapeNode)?.fillColor = SKColor(red: 0.1, green: 0.02, blue: 0.0, alpha: (elapsed / 0.6) * 0.7)
        })

        let d: TimeInterval = 0.3

        let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 44
        gameOverLabel.fontColor = .white
        gameOverLabel.alpha = 0
        gameOverLabel.zPosition = 100
        gameOverLabel.position = CGPoint(x: 0, y: 80)
        cameraNode.addChild(gameOverLabel)

        let climbedLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        climbedLabel.text = "You climbed \(score) stairs"
        climbedLabel.fontSize = 24
        climbedLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.7, alpha: 1.0)
        climbedLabel.alpha = 0
        climbedLabel.zPosition = 100
        climbedLabel.position = CGPoint(x: 0, y: 30)
        cameraNode.addChild(climbedLabel)

        let scoreNumber = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreNumber.text = "\(score)"
        scoreNumber.fontSize = 72
        scoreNumber.fontColor = SKColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0)
        scoreNumber.alpha = 0
        scoreNumber.zPosition = 100
        scoreNumber.position = CGPoint(x: 0, y: -40)
        cameraNode.addChild(scoreNumber)

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

        let tapRestart = SKLabelNode(fontNamed: "AvenirNext-Medium")
        tapRestart.text = "TAP TO RESTART"
        tapRestart.fontSize = 20
        tapRestart.fontColor = .white
        tapRestart.alpha = 0
        tapRestart.zPosition = 100
        tapRestart.position = CGPoint(x: 0, y: -160)
        cameraNode.addChild(tapRestart)

        gameOverLabel.run(SKAction.sequence([SKAction.wait(forDuration: d), SKAction.fadeIn(withDuration: 0.4)]))
        climbedLabel.run(SKAction.sequence([SKAction.wait(forDuration: d + 0.2), SKAction.fadeIn(withDuration: 0.4)]))
        scoreNumber.run(SKAction.sequence([
            SKAction.wait(forDuration: d + 0.4),
            SKAction.group([SKAction.fadeIn(withDuration: 0.3),
                            SKAction.sequence([SKAction.scale(to: 1.3, duration: 0.15), SKAction.scale(to: 1.0, duration: 0.15)])])
        ]))
        highScoreLabel.run(SKAction.sequence([SKAction.wait(forDuration: d + 0.7), SKAction.fadeIn(withDuration: 0.4)]))
        if isNewBest {
            highScoreLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: d + 0.7),
                SKAction.repeatForever(SKAction.sequence([SKAction.scale(to: 1.1, duration: 0.5), SKAction.scale(to: 1.0, duration: 0.5)]))
            ]))
        }
        tapRestart.run(SKAction.sequence([
            SKAction.wait(forDuration: d + 1.0),
            SKAction.fadeIn(withDuration: 0.4),
            SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.3, duration: 0.7), SKAction.fadeAlpha(to: 1.0, duration: 0.7)]))
        ]))
        run(SKAction.sequence([
            SKAction.wait(forDuration: d + 1.2),
            SKAction.run { [weak self] in self?.canRestart = true }
        ]))
    }

    private func restartGame() {
        let newScene = GameScene(size: self.size)
        newScene.scaleMode = .aspectFill
        view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 0.3))
    }
}
