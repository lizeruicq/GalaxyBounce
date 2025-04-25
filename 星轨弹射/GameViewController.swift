//
//  GameViewController.swift
//  game_two
//
//  Created by zerui lī on 2025/4/8.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // 创建主菜单场景
            let scene = MainMenuScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            
            // 设置视图属性
            view.presentScene(scene)
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
