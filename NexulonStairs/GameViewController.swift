import UIKit
import SpriteKit

class GameViewController: UIViewController {
    private var hasPresented = false

    override func loadView() {
        self.view = SKView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard !hasPresented, let skView = self.view as? SKView else { return }
        hasPresented = true

        let scene = MenuScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
        skView.ignoresSiblingOrder = true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
