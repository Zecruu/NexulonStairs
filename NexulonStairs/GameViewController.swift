import UIKit
import SpriteKit

class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = self.view as? SKView else {
            let skView = SKView(frame: self.view.bounds)
            skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(skView)
            presentScene(in: skView)
            return
        }
        presentScene(in: skView)
    }

    private func presentScene(in skView: SKView) {
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

    override func loadView() {
        self.view = SKView()
    }
}
