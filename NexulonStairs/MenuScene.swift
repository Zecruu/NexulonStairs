import SpriteKit

class MenuScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)

        // Title
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "NEXULON"
        title.fontSize = 48
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        addChild(title)

        let subtitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        subtitle.text = "STAIRS"
        subtitle.fontSize = 36
        subtitle.fontColor = SKColor(red: 1.0, green: 0.4, blue: 0.2, alpha: 1.0)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.7 - 50)
        addChild(subtitle)

        // Tap to play
        let play = SKLabelNode(fontNamed: "AvenirNext-Medium")
        play.text = "TAP TO PLAY"
        play.fontSize = 24
        play.fontColor = .white
        play.position = CGPoint(x: size.width / 2, y: size.height * 0.4)
        play.name = "playButton"
        addChild(play)

        // Pulse animation
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.8)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        play.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))

        // High score
        let highScore = UserDefaults.standard.integer(forKey: "highScore")
        if highScore > 0 {
            let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
            scoreLabel.text = "BEST: \(highScore)"
            scoreLabel.fontSize = 20
            scoreLabel.fontColor = SKColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0)
            scoreLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.3)
            addChild(scoreLabel)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = .aspectFill
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(gameScene, transition: transition)
    }
}
