import SpriteKit
import GameplayKit
import UIKit

class MainMenuScene: SKScene {

    override func didMove(to view: SKView) {
        // 设置背景颜色为黑色（太空背景）
        backgroundColor = SKColor.black
        // 播放背景音乐
        AudioManager.shared.playBackgroundMusic()
        
        // 创建星空背景
        BackgroundUtils.createStarryBackground(in: self)
        
        // 创建游戏标题
        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLabel.text = "星轨弹射"
        titleLabel.fontSize = 80
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width/2, y: size.height * 0.7)
        titleLabel.zPosition = 10
        addChild(titleLabel)

        // 创建新游戏按钮
        let newGameButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 10)
        newGameButton.fillColor = SKColor(red: CGFloat.random(in: 0...1),
                                          green: CGFloat.random(in: 0...1),
                                          blue: CGFloat.random(in: 0...1),
                                          alpha: 0.8)
        newGameButton.position = CGPoint(x: size.width/2, y: size.height * 0.4)
        newGameButton.name = "newGameButton"
        newGameButton.zPosition = 10

        let newGameLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        newGameLabel.text = "新游戏"
        newGameLabel.fontSize = 30
        newGameLabel.fontColor = .white
        newGameLabel.position = CGPoint(x: 0, y: -3)
        newGameLabel.verticalAlignmentMode = .center
        newGameLabel.horizontalAlignmentMode = .center
        newGameButton.addChild(newGameLabel)

        addChild(newGameButton)

        // 创建继续游戏按钮
        let continueButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 10)
        continueButton.fillColor = SKColor(red: CGFloat.random(in: 0...1),
                                          green: CGFloat.random(in: 0...1),
                                          blue: CGFloat.random(in: 0...1),
                                          alpha: 0.8)
        continueButton.position = CGPoint(x: size.width/2, y: size.height * 0.3)
        continueButton.name = "continueButton"
        continueButton.zPosition = 10

        let continueLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        continueLabel.text = "继续游戏"
        continueLabel.fontSize = 30
        continueLabel.fontColor = .white
        continueLabel.position = CGPoint(x: 0, y: -3)
        continueLabel.verticalAlignmentMode = .center
        continueLabel.horizontalAlignmentMode = .center
        continueButton.addChild(continueLabel)

        addChild(continueButton)

        // 添加当前关卡记录
        let currentLevel = LevelManager.shared.getCurrentLevel()
        let levelRecordLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        levelRecordLabel.text = "当前：第\(currentLevel)关"
        levelRecordLabel.fontSize = 24
        levelRecordLabel.fontColor = .white
        levelRecordLabel.position = CGPoint(x: size.width/2, y: size.height * 0.2)
        levelRecordLabel.zPosition = 10
        addChild(levelRecordLabel)
    }

    // 触摸处理方法
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)

        for node in nodes {
            if node.name == "newGameButton" {
                // 点击效果
                let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
                let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                let clickSequence = SKAction.sequence([scaleUp, scaleDown])
                node.run(clickSequence)

                // 重置关卡记录
                LevelManager.shared.resetLevel()

                // 延迟进入第一关
                let wait = SKAction.wait(forDuration: 0.2)
                let startGame = SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let gameScene = GameScene(size: self.size)
                    gameScene.scaleMode = self.scaleMode
                    gameScene.currentLevel = 1
                    let transition = SKTransition.fade(withDuration: 0.5)
                    self.view?.presentScene(gameScene, transition: transition)
                }
                run(SKAction.sequence([wait, startGame]))
                return
            } else if node.name == "continueButton" {
                // 点击效果
                let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
                let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                let clickSequence = SKAction.sequence([scaleUp, scaleDown])
                node.run(clickSequence)

                // 获取当前关卡
                let currentLevel = LevelManager.shared.getCurrentLevel()

                // 延迟进入当前关卡
                let wait = SKAction.wait(forDuration: 0.2)
                let startGame = SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let gameScene = GameScene(size: self.size)
                    gameScene.scaleMode = self.scaleMode
                    gameScene.currentLevel = currentLevel
                    let transition = SKTransition.fade(withDuration: 0.5)
                    self.view?.presentScene(gameScene, transition: transition)
                }
                run(SKAction.sequence([wait, startGame]))
                return
            }
        }
    }
}
