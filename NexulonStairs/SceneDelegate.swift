import UIKit
import SpriteKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)

        let skView = SKView(frame: window.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true

        let gameScene = MenuScene(size: CGSize(width: 390, height: 844))
        gameScene.scaleMode = .aspectFill
        skView.presentScene(gameScene)

        let vc = UIViewController()
        vc.view = skView

        window.rootViewController = vc
        window.makeKeyAndVisible()
        self.window = window
    }
}
