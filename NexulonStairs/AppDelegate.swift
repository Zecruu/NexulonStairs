import UIKit
import SpriteKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window

        let skView = SKView(frame: window.bounds)
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true

        let scene = MenuScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)

        let vc = UIViewController()
        vc.view = skView

        window.rootViewController = vc
        window.makeKeyAndVisible()

        return true
    }
}
