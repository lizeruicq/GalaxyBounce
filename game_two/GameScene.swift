//
//  GameScene.swift
//  game_two
//
//  Created by zerui lī on 2025/4/8.
//

import SpriteKit
import GameplayKit
import Foundation
import UIKit

// 在游戏场景中定义游戏状态枚举
// 注意：如果项目中已有GameState.swift，则需要将其移除
enum GameState {
    case mainMenu
    case playing
    case gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    private var gameState: GameState = .playing
    // 添加关卡相关变量
    var currentLevel: Int = 1
    private var levelLabel: SKLabelNode!
    private var isLevelCompleted: Bool = false
    // 添加移动次数限制
    private var hasMoved: Bool = false
    private var isShipStopped: Bool = false
    // 添加轨迹相关变量
    private var trailPositions: [CGPoint] = []
    private let maxTrailLength: Int = 100 // 最大轨迹点数
    private var trailNode: SKShapeNode?
    private var lastTrailUpdateTime: TimeInterval = 0
    private let trailUpdateInterval: TimeInterval = 0.02 // 轨迹更新间隔
    // 添加母船移动状态变量
    private var isMotherShipMoving: Bool = true
    // 添加陨石移动状态变量
    private var isAsteroidsMoving: Bool = true

    // 添加返回主页按钮相关属性
    private var homeButton: SKShapeNode!
    private var homeLabel: SKLabelNode!

    // // 初始化方法
    // override init(size: CGSize) {
    //     super.init(size: size)
    //     // 初始化游戏状态为游戏中
    //     gameState = .playing
    // }

    // required init?(coder aDecoder: NSCoder) {
    //     super.init(coder: aDecoder)
    // }

    // // 玩家飞船
    // private var playerShip: SKSpriteNode!// 
    // 物理体类别
    private let playerCategory: UInt32 = 0x1 << 0
    private let borderCategory: UInt32 = 0x1 << 1
    private let motherShipCategory: UInt32 = 0x1 << 2
    private let asteroidCategory: UInt32 = 0x1 << 3
    // 触摸相关变量
    private var touchStartLocation: CGPoint?
    private var touchStartTime: TimeInterval = 0
    // 敌人母舰
    private var motherShip: SKSpriteNode?
    // 陨石相关
    private var asteroids: [SKSpriteNode] = []
    private let baseAsteroidSpeed: CGFloat = 20.0 // 降低基础移动速度
    private var asteroidVelocities: [CGVector] = []
    private var lastAsteroidDirectionChangeTime: [TimeInterval] = []
    private let asteroidDirectionChangeInterval: TimeInterval = 3.0 // 方向改变间隔
    // 飞船物理参数
    private let maxImpulse: CGFloat = 400.0 // 最大冲量
    private let dampingFactor: CGFloat = 0.95 // 阻尼因子
    // 母船移动参数
    private var motherShipVelocity: CGVector = .zero
    private let baseMotherShipSpeed: CGFloat = 50.0 // 基础移动速度
    private var motherShipSpeed: CGFloat = 50.0 // 当前移动速度
    private var lastDirectionChangeTime: TimeInterval = 0
    private let directionChangeInterval: TimeInterval = 2.0 // 方向改变间隔

    // 初始化方法
    override init(size: CGSize) {
        super.init(size: size)
        // 初始化游戏状态为游戏中
        gameState = .playing
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // 玩家飞船
    private var playerShip: SKSpriteNode!

    override func didMove(to view: SKView) {
        print("场景已加载")
        // 设置背景颜色为黑色（太空背景）
        backgroundColor = SKColor.black

        // 创建星空背景
        BackgroundUtils.createStarryBackground(in: self)

        // 创建屏幕边界
        createScreenBorders()

        // 创建玩家飞船
        createPlayerShip()

        // 创建敌人母舰
        createMotherShip()

        // 创建关卡标签
        createLevelLabel()

        // 从第三关开始创建陨石
        if currentLevel >= 3 {
            createAsteroids()
        }

        // 设置物理世界的重力为零（太空环境）
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)

        // 设置物理世界的代理
        physicsWorld.contactDelegate = self
        
        // 创建返回主页按钮
        createHomeButton()
    }

    // 创建玩家UFO飞船（俯视角）
    private func createPlayerShip() {
        // 创建飞船主体
        playerShip = SKSpriteNode()
        playerShip.size = CGSize(width: 60, height: 60) // 正圆形尺寸
        
        // 设置玩家飞船的层级
        playerShip.zPosition = 2 // 确保玩家飞船在最上层

        // 创建轨迹节点
        trailNode = SKShapeNode()
        trailNode?.strokeColor = SKColor(red: CGFloat.random(in: 0...1),
                                      green: CGFloat.random(in: 0...1),
                                      blue: CGFloat.random(in: 0...1),
                                      alpha: 0.8)
        trailNode?.lineWidth = 3
        trailNode?.name = "trail"
        addChild(trailNode!)

        // 创建 UFO 主体 - 外圈
        let outerRing = SKShapeNode(circleOfRadius: 30)
        outerRing.fillColor = SKColor(red: 0.7, green: 0.7, blue: 0.8, alpha: 1.0) // 金属银色
        outerRing.strokeColor = SKColor(red: 0.8, green: 0.8, blue: 0.9, alpha: 1.0)
        outerRing.lineWidth = 1.5
        outerRing.position = CGPoint(x: 0, y: 0)
        playerShip.addChild(outerRing)

        // 创建中间环
        let middleRing = SKShapeNode(circleOfRadius: 25)
        middleRing.fillColor = SKColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 1.0) // 稍深的金属色
        middleRing.strokeColor = SKColor(red: 0.7, green: 0.7, blue: 0.8, alpha: 1.0)
        middleRing.lineWidth = 1
        middleRing.position = CGPoint(x: 0, y: 0)
        playerShip.addChild(middleRing)

        // 创建中央驾驶舱
        let cockpit = SKShapeNode(circleOfRadius: 15)
        cockpit.fillColor = SKColor(red: 0.3, green: 0.8, blue: 0.9, alpha: 0.8) // 半透明蓝色
        cockpit.strokeColor = SKColor.white
        cockpit.lineWidth = 1
        cockpit.position = CGPoint(x: 0, y: 0)
        playerShip.addChild(cockpit)

        // 添加环形装饰线
        let decorativeLine = SKShapeNode(circleOfRadius: 20)
        decorativeLine.fillColor = SKColor.clear
        decorativeLine.strokeColor = SKColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 0.6)
        decorativeLine.lineWidth = 1
        decorativeLine.position = CGPoint(x: 0, y: 0)
        playerShip.addChild(decorativeLine)

        // 创建灯光容器节点
        let lightsContainer = SKNode()
        playerShip.addChild(lightsContainer)

        // 添加外围灯光
        for i in 0..<8 {
            let angle = CGFloat(i) * .pi / 4.0
            let radius: CGFloat = 27

            let light = SKShapeNode(circleOfRadius: 2.5)
            light.fillColor = SKColor.yellow
            light.strokeColor = SKColor.orange
            light.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            lightsContainer.addChild(light)

            // 为每个灯光添加闪烁效果
            let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.5)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
            let wait = SKAction.wait(forDuration: Double.random(in: 0.1...0.3))
            let sequence = SKAction.sequence([fadeOut, fadeIn, wait])
            light.run(SKAction.repeatForever(sequence))
        }

        // 添加顺时针旋转动画
        let rotateActionl = SKAction.rotate(byAngle: -CGFloat.pi * 2, duration: 10.0)
        lightsContainer.run(SKAction.repeatForever(rotateActionl))

        // 添加中心发光效果
        let centerGlow = SKShapeNode(circleOfRadius: 10)
        centerGlow.fillColor = SKColor(red: 0.3, green: 0.8, blue: 0.9, alpha: 0.4)
        centerGlow.strokeColor = SKColor.clear
        centerGlow.position = CGPoint(x: 0, y: 0)
        playerShip.addChild(centerGlow)

        // 添加发光效果的脉动
        let glowFadeOut = SKAction.fadeAlpha(to: 0.1, duration: 1.0)
        let glowFadeIn = SKAction.fadeAlpha(to: 0.4, duration: 1.0)
        let glowPulse = SKAction.sequence([glowFadeOut, glowFadeIn])
        centerGlow.run(SKAction.repeatForever(glowPulse))

        // 添加微妙的旋转效果
        let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 20.0) // 慢速旋转
        outerRing.run(SKAction.repeatForever(rotateAction))

        // 反方向旋转的内环
        let reverseRotateAction = SKAction.rotate(byAngle: -.pi * 2, duration: 15.0)
        decorativeLine.run(SKAction.repeatForever(reverseRotateAction))

        // 设置飞船位置（屏幕底部偏上一点）
        playerShip.position = CGPoint(x: size.width / 2, y: size.height * 0.15)

        // 添加物理体 - 使用圆形
        playerShip.physicsBody = SKPhysicsBody(circleOfRadius: 30)
        playerShip.physicsBody?.isDynamic = true
        playerShip.physicsBody?.affectedByGravity = false
        playerShip.physicsBody?.categoryBitMask = playerCategory
        playerShip.physicsBody?.contactTestBitMask = borderCategory
        playerShip.physicsBody?.collisionBitMask = borderCategory
        // 设置物理属性
        playerShip.physicsBody?.linearDamping = 0.5 // 线性阻尼
        playerShip.physicsBody?.angularDamping = 0.7 // 角速度阻尼
        playerShip.physicsBody?.restitution = 0.8 // 弹性（反弹系数）
        playerShip.physicsBody?.friction = 0.2 // 摩擦力
        playerShip.physicsBody?.allowsRotation = false // 不允许旋转
        playerShip.name = "playerShip"

        addChild(playerShip)
    }

    // 创建敌人母舰
    private func createMotherShip() {
        // 创建母舰主体
        motherShip = SKSpriteNode()
        guard let motherShip = motherShip else { return }

        // 设置母船的层级
        motherShip.zPosition = 2 // 确保母船在陨石上方

        // 计算母船大小（随关卡增加而减小）
        let baseSize: CGFloat = 80 // 基础大小
        let minSize: CGFloat = 60 // 最小大小（
        let sizeDecreasePerLevel: CGFloat = 3 // 每关减小的大小
        
        // 计算当前关卡的大小
        let currentSize = max(minSize, baseSize - CGFloat(currentLevel - 1) * sizeDecreasePerLevel)
        let motherShipSize = CGSize(width: currentSize, height: currentSize)
        motherShip.size = motherShipSize

        // 创建母舰外圈
        let outerRing = SKShapeNode(circleOfRadius: currentSize * 0.75) // 外圈半径随大小变化
        outerRing.fillColor = SKColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0) // 暗色金属
        outerRing.strokeColor = SKColor(red: 0.5, green: 0.5, blue: 0.6, alpha: 1.0)
        outerRing.lineWidth = 2
        outerRing.position = CGPoint(x: 0, y: 0)
        motherShip.addChild(outerRing)

        // 创建中间环
        let middleRing = SKShapeNode(circleOfRadius: currentSize * 0.5) // 中间环半径随大小变化
        middleRing.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0) // 更暗的金属
        middleRing.strokeColor = SKColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0)
        middleRing.lineWidth = 1.5
        middleRing.position = CGPoint(x: 0, y: 0)
        motherShip.addChild(middleRing)

        // 创建中央核心
        let core = SKShapeNode(circleOfRadius: currentSize * 0.3125) // 核心半径随大小变化
        // 生成随机颜色
        let randomColor = SKColor(
            red: CGFloat.random(in: 0.3...1.0),
            green: CGFloat.random(in: 0.3...1.0),
            blue: CGFloat.random(in: 0.3...1.0),
            alpha: 0.8
        )
        core.fillColor = randomColor
        core.strokeColor = randomColor.withAlphaComponent(1.0)
        core.lineWidth = 2
        core.position = CGPoint(x: 0, y: 0)
        motherShip.addChild(core)

        // 创建灯光容器节点
        let lightsContainer = SKNode()
        motherShip.addChild(lightsContainer)

        // 添加外围灯光
        for i in 0..<12 {
            let angle = CGFloat(i) * .pi / 6.0
            let radius: CGFloat = currentSize * 0.625 // 灯光半径随大小变化

            let light = SKShapeNode(circleOfRadius: 3)
            light.fillColor = SKColor(red: 0.9, green: 0.7, blue: 0.3, alpha: 1.0)
            light.strokeColor = SKColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
            light.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            lightsContainer.addChild(light)

            // 为每个灯光添加闪烁效果
            let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.5)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
            let wait = SKAction.wait(forDuration: Double.random(in: 0.1...0.3))
            let sequence = SKAction.sequence([fadeOut, fadeIn, wait])
            light.run(SKAction.repeatForever(sequence))
        }

        // 添加逆时针旋转动画
        let rotateActionl = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 10.0)
        lightsContainer.run(SKAction.repeatForever(rotateActionl))

        // 添加核心发光效果
        let coreGlow = SKShapeNode(circleOfRadius: currentSize * 0.375) // 发光效果半径随大小变化
        coreGlow.fillColor = SKColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 0.4)
        coreGlow.strokeColor = SKColor.clear
        coreGlow.position = CGPoint(x: 0, y: 0)
        motherShip.addChild(coreGlow)

        // 添加发光效果的脉动
        let glowFadeOut = SKAction.fadeAlpha(to: 0.2, duration: 1.5)
        let glowFadeIn = SKAction.fadeAlpha(to: 0.6, duration: 1.5)
        let glowPulse = SKAction.sequence([glowFadeOut, glowFadeIn])
        coreGlow.run(SKAction.repeatForever(glowPulse))

        // 添加旋转效果
        let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 30.0) // 缓慢旋转
        outerRing.run(SKAction.repeatForever(rotateAction))

        // 反方向旋转的内环
        let reverseRotateAction = SKAction.rotate(byAngle: -.pi * 2, duration: 20.0)
        middleRing.run(SKAction.repeatForever(reverseRotateAction))

        // 添加缩放效果模拟上升和下降
        let scaleUp = SKAction.scale(to: 1.1, duration: 4.0)
        let scaleDown = SKAction.scale(to: 0.9, duration: 4.0)
        let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
        motherShip.run(SKAction.repeatForever(scaleSequence))

        // 随机位置（保证不会太靠近屏幕边缘和玩家出生区域）
        let margin: CGFloat = currentSize // 边缘距离随大小变化
        let playerSpawnAreaHeight: CGFloat = size.height * 0.3 // 玩家出生区域高度
        let randomX = CGFloat.random(in: margin...(size.width - margin))
        let randomY = CGFloat.random(in: (size.height * 0.4)...(size.height * 0.7)) // 主要在屏幕上半部分
        motherShip.position = CGPoint(x: randomX, y: randomY)

        // 设置母船速度（随关卡增加）
        motherShipSpeed = baseMotherShipSpeed * (1.0 + CGFloat(currentLevel - 1) * 0.2)
        
        // 设置初始随机方向
        let randomAngle = CGFloat.random(in: 0...(CGFloat.pi * 2))
        motherShipVelocity = CGVector(
            dx: cos(randomAngle) * motherShipSpeed,
            dy: sin(randomAngle) * motherShipSpeed
        )

        // 设置物理体（参与碰撞）
        motherShip.physicsBody = SKPhysicsBody(circleOfRadius: currentSize * 0.875) // 物理体半径随大小变化
        motherShip.physicsBody?.isDynamic = true // 动态物体
        motherShip.physicsBody?.affectedByGravity = false
        motherShip.physicsBody?.categoryBitMask = motherShipCategory
        motherShip.physicsBody?.contactTestBitMask = playerCategory | borderCategory // 移除与陨石的碰撞检测
        motherShip.physicsBody?.collisionBitMask = borderCategory // 移除与陨石的碰撞
        motherShip.physicsBody?.restitution = 1.0 // 完全弹性碰撞
        motherShip.physicsBody?.linearDamping = 0.0 // 无阻尼
        motherShip.name = "motherShip"

        addChild(motherShip)
    }

    // 创建屏幕边界
    private func createScreenBorders() {
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        borderBody.friction = 0
        borderBody.restitution = 1.0 // 完全弹性反弹
        borderBody.categoryBitMask = borderCategory
        borderBody.contactTestBitMask = playerCategory
        borderBody.collisionBitMask = playerCategory

        // 创建一个边界节点
        let border = SKNode()
        border.physicsBody = borderBody
        border.position = CGPoint(x: 0, y: 0)
        border.name = "border"
        addChild(border)
    }

    // 创建关卡标签
    private func createLevelLabel() {
        levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        levelLabel.text = "第\(currentLevel)关"
        levelLabel.fontSize = 20
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(x: 50, y: size.height - 40)
        levelLabel.zPosition = 10
        addChild(levelLabel)
    }

    // 创建返回主页按钮
    private func createHomeButton() {
        // 创建按钮容器
        homeButton = SKShapeNode(circleOfRadius: 15)
        homeButton.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.8)
        homeButton.strokeColor = SKColor.white
        homeButton.lineWidth = 2
        homeButton.position = CGPoint(x: size.width - 40, y: size.height - 35)
        homeButton.zPosition = 100
        homeButton.name = "homeButton"
        
        // 创建按钮标签
        homeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        homeLabel.text = "←"
        homeLabel.fontSize = 20
        homeLabel.fontColor = .white
        homeLabel.position = CGPoint(x: 0, y: -0.5)
        homeLabel.horizontalAlignmentMode = .center
        homeLabel.verticalAlignmentMode = .center
        homeButton.addChild(homeLabel)
        
        addChild(homeButton)
    }

    // 触摸处理方法
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = self.nodes(at: location)
        
        // 检查是否点击了返回主页按钮
        if nodes.contains(where: { $0.name == "homeButton" }) {
            LevelManager.shared.saveLevel(currentLevel)
            // 返回主菜单
            let menuScene = MainMenuScene(size: size)
            menuScene.scaleMode = scaleMode
            let transition = SKTransition.fade(withDuration: 0.5)
            view?.presentScene(menuScene, transition: transition)
            return
        }

        if isLevelCompleted {
            handleLevelCompleteTouches(at: location)
            return
        }

        // 如果游戏结束，检查是否点击了按钮
        if gameState == .gameOver {
            handleGameOverTouches(at: location)
            return
        } else if gameState == .playing {
            // 如果已经移动过，不再响应触摸
            if hasMoved {
                return
            }
            // 记录触摸开始位置和时间
            touchStartLocation = location
            touchStartTime = CACurrentMediaTime()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 我们不需要在移动时做任何处理，只需要在触摸结束时计算冲量
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard gameState == .playing,
              let touch = touches.first,
              let startLocation = touchStartLocation else { return }

        // 如果已经移动过，不再响应
        if hasMoved {
            return
        }

        // 计算触摸结束位置
        let endLocation = touch.location(in: self)

        // 计算触摸时间
        let touchDuration = CACurrentMediaTime() - touchStartTime

        // 计算触摸距离和方向
        let dx = endLocation.x - startLocation.x
        let dy = endLocation.y - startLocation.y
        let distance = sqrt(dx * dx + dy * dy)

        // 如果距离太小，忽略这次触摸
        if distance < 10 { return }

        // 计算冲量大小（基于距离和时间）
        // 触摸时间越短，冲量越大
        let speed = distance / CGFloat(max(touchDuration, 0.1))
        let impulseMultiplier = min(speed / 100.0, 1.0) // 将速度映射到 0-1 范围
        let impulseStrength = maxImpulse * impulseMultiplier

        // 计算冲量方向
        let normalizedDx = dx / distance
        let normalizedDy = dy / distance

        // 应用冲量
        playerShip.physicsBody?.applyImpulse(CGVector(dx: normalizedDx * impulseStrength,
                                                     dy: normalizedDy * impulseStrength))

        // 播放飞船移动音效
        AudioManager.shared.playSoundEffect("shipMove", in: self)

        // 标记已经移动过
        hasMoved = true
        // 停止母船移动
        isMotherShipMoving = false
        // 停止陨石移动
        isAsteroidsMoving = false

        // 重置触摸跟踪变量
        touchStartLocation = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 重置触摸跟踪变量
        touchStartLocation = nil
    }

    // 显示关卡完成界面
    private func showLevelCompleteMenu() {
        LevelManager.shared.saveLevel(currentLevel)
        // 创建关卡完成标签
        let levelCompleteLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        levelCompleteLabel.text = "关卡完成！"
        levelCompleteLabel.fontSize = 60
        levelCompleteLabel.position = CGPoint(x: size.width/2, y: size.height * 0.7)
        levelCompleteLabel.zPosition = 10
        addChild(levelCompleteLabel)

        // 创建继续按钮
        let continueButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 10)
        continueButton.fillColor = SKColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
        continueButton.position = CGPoint(x: size.width/2, y: size.height * 0.4)
        continueButton.name = "continueButton"
        continueButton.zPosition = 10

        let continueLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        continueLabel.text = "继续"
        continueLabel.fontSize = 30
        continueLabel.fontColor = .white
        continueLabel.position = CGPoint(x: 0, y: -10)
        continueLabel.verticalAlignmentMode = .center
        continueLabel.horizontalAlignmentMode = .center
        continueButton.addChild(continueLabel)

        addChild(continueButton)

        // 创建返回主页按钮
        let menuButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 10)
        menuButton.fillColor = SKColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
        menuButton.position = CGPoint(x: size.width/2, y: size.height * 0.3)
        menuButton.name = "menuButton"
        menuButton.zPosition = 10

        let menuLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        menuLabel.text = "返回主页"
        menuLabel.fontSize = 30
        menuLabel.fontColor = .white
        menuLabel.position = CGPoint(x: 0, y: -10)
        menuLabel.verticalAlignmentMode = .center
        menuLabel.horizontalAlignmentMode = .center
        menuButton.addChild(menuLabel)

        addChild(menuButton)
    }

    // 处理关卡完成界面的按钮点击
    private func handleLevelCompleteTouches(at location: CGPoint) {
        let nodes = self.nodes(at: location)
        for node in nodes {
            if node.name == "continueButton" {
                // 点击效果
                let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
                let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                let clickSequence = SKAction.sequence([scaleUp, scaleDown])
                node.run(clickSequence)

                // 延迟进入下一关
                let wait = SKAction.wait(forDuration: 0.2)
                let nextLevel = SKAction.run { [weak self] in
                    self?.startNextLevel()
                }
                run(SKAction.sequence([wait, nextLevel]))
                return
            } else if node.name == "menuButton" {
                // 点击效果
                let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
                let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                let clickSequence = SKAction.sequence([scaleUp, scaleDown])
                node.run(clickSequence)

                // 返回主菜单
                let wait = SKAction.wait(forDuration: 0.2)
                let goToMenu = SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let menuScene = MainMenuScene(size: self.size)
                    menuScene.scaleMode = self.scaleMode
                    let transition = SKTransition.fade(withDuration: 0.5)
                    self.view?.presentScene(menuScene, transition: transition)
                }
                run(SKAction.sequence([wait, goToMenu]))
                return
            }
        }
    }

    // 开始下一关
    private func startNextLevel() {
        // 增加关卡数
        currentLevel += 1
        
        // 创建新的游戏场景
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode
        gameScene.currentLevel = currentLevel
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(gameScene, transition: transition)
    }

    // 修改游戏更新循环
    override func update(_ currentTime: TimeInterval) {
        if gameState != .playing { return }

        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }

        // 更新母船位置
        if let motherShip = motherShip, isMotherShipMoving {
            // 检查是否需要改变方向
            if currentTime - lastDirectionChangeTime > directionChangeInterval {
                // 随机改变方向
                let randomAngle = CGFloat.random(in: 0...(CGFloat.pi * 2))
                motherShipVelocity = CGVector(
                    dx: cos(randomAngle) * motherShipSpeed,
                    dy: sin(randomAngle) * motherShipSpeed
                )
                lastDirectionChangeTime = currentTime
            }
            
            // 应用移动
            motherShip.position = CGPoint(
                x: motherShip.position.x + motherShipVelocity.dx * CGFloat(dt),
                y: motherShip.position.y + motherShipVelocity.dy * CGFloat(dt)
            )
            
            // 检查是否超出边界
            let margin: CGFloat = 70
            let playerSpawnAreaHeight: CGFloat = size.height * 0.3
            
            // 水平边界检查
            if motherShip.position.x < margin {
                motherShip.position.x = margin
                motherShipVelocity.dx = abs(motherShipVelocity.dx)
            } else if motherShip.position.x > size.width - margin {
                motherShip.position.x = size.width - margin
                motherShipVelocity.dx = -abs(motherShipVelocity.dx)
            }
            
            // 垂直边界检查
            if motherShip.position.y < size.height * 0.3 + margin {
                motherShip.position.y = size.height * 0.3 + margin
                motherShipVelocity.dy = abs(motherShipVelocity.dy)
            } else if motherShip.position.y > size.height - margin {
                motherShip.position.y = size.height - margin
                motherShipVelocity.dy = -abs(motherShipVelocity.dy)
            }
        }

        // 更新玩家飞船轨迹
        if let velocity = playerShip.physicsBody?.velocity {
            let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
            
            if speed > 5 && currentTime - lastTrailUpdateTime > trailUpdateInterval {
                // 记录当前位置
                trailPositions.append(playerShip.position)
                
                // 限制轨迹长度
                if trailPositions.count > maxTrailLength {
                    trailPositions.removeFirst()
                }
                
                // 更新轨迹显示
                updateTrailDisplay()
                
                lastTrailUpdateTime = currentTime
            } else if speed <= 5 && !trailPositions.isEmpty {
                // 如果速度很慢，清除轨迹
                trailPositions.removeAll()
                updateTrailDisplay()
            }
        }

        // 检查飞船是否停止
        if let velocity = playerShip.physicsBody?.velocity {
            let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
            
            // 如果速度很小，则完全停下来
            if speed < 5 {
                playerShip.physicsBody?.velocity = CGVector.zero
                
                // 如果飞船已经移动过且现在停止，检查是否碰到母船
                if hasMoved && !isShipStopped {
                    isShipStopped = true
                    // 恢复母船移动
                    isMotherShipMoving = true
                    // 停止陨石移动
                    isAsteroidsMoving = false
                    // 如果母船还存在，说明没有碰到，游戏失败
                    if motherShip != nil {
                        endGame()
                    }
                }
            } else {
                // 否则应用额外的阻尼
                playerShip.physicsBody?.velocity = CGVector(
                    dx: velocity.dx * dampingFactor,
                    dy: velocity.dy * dampingFactor
                )
            }
        }
        
        // 更新陨石位置
        if isAsteroidsMoving {
            // for asteroid in asteroids {
            //     // 获取陨石当前速度
            //     if let velocity = asteroid.physicsBody?.velocity {
            //         // 计算陨石速度
            //         let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
                    
            //         // 如果陨石速度太小，则完全停下来
            //         if speed < 5 {
            //             asteroid.physicsBody?.velocity = CGVector.zero
            //         } else {
            //             // 否则应用额外的阻尼
            //             asteroid.physicsBody?.velocity = CGVector(
            //                 dx: velocity.dx * dampingFactor,
            //                 dy: velocity.dy * dampingFactor
            //             )
            //         }
            //     }

            for (index, asteroid) in asteroids.enumerated() {
            // 检查是否需要改变方向
            if currentTime - lastAsteroidDirectionChangeTime[index] > asteroidDirectionChangeInterval {
                // 随机改变方向
                let randomAngle = CGFloat.random(in: 0...(CGFloat.pi * 2))
                let speed = baseAsteroidSpeed * (0.5 + CGFloat(currentLevel - 3) * 0.05) // 降低速度增长
                asteroidVelocities[index] = CGVector(
                    dx: cos(randomAngle) * speed,
                    dy: sin(randomAngle) * speed
                )
                lastAsteroidDirectionChangeTime[index] = currentTime
            }
            
            // 应用移动
            asteroid.position = CGPoint(
                x: asteroid.position.x + asteroidVelocities[index].dx * CGFloat(dt),
                y: asteroid.position.y + asteroidVelocities[index].dy * CGFloat(dt)
            )
            
            // 检查是否超出边界
            let margin: CGFloat = asteroid.size.width / 2
            let playerSpawnAreaHeight: CGFloat = size.height * 0.3
            
            // 水平边界检查
            if asteroid.position.x < margin || asteroid.position.x > size.width - margin {
                asteroidVelocities[index].dx *= -1
            }
                
                // 限制陨石不能低于玩家飞船的高度
                let minY = size.height * 0.3 + 50 // 玩家飞船区域上方50点
                if asteroid.position.y < minY {
                    asteroid.position.y = minY
                    // 如果陨石碰到下边界，反弹
                    if let velocity = asteroid.physicsBody?.velocity {
                        asteroid.physicsBody?.velocity = CGVector(
                            dx: velocity.dx,
                            dy: abs(velocity.dy)
                        )
                    }
                }
            }
        }
        else {
            for (index, asteroid) in asteroids.enumerated() {
                asteroidVelocities[index] = CGVector(
                    dx: 0,
                    dy: 0
                )
            }
            
        }
        
        self.lastUpdateTime = currentTime
    }

    // 更新轨迹显示
    private func updateTrailDisplay() {
        guard let trailNode = trailNode else { return }
        
        if trailPositions.count < 2 {
            trailNode.path = nil
            return
        }
        
        let path = CGMutablePath()
        path.move(to: trailPositions[0])
        
        for i in 1..<trailPositions.count {
            path.addLine(to: trailPositions[i])
        }
        
        trailNode.path = path
        
        // 随机改变轨迹颜色
        if Double.random(in: 0...1) < 0.1 { // 10%的概率改变颜色
            trailNode.strokeColor = SKColor(red: CGFloat.random(in: 0...1),
                                          green: CGFloat.random(in: 0...1),
                                          blue: CGFloat.random(in: 0...1),
                                          alpha: 0.8)
        }
    }

    // 在飞船碰撞时重置轨迹
    private func resetTrail() {
        trailPositions.removeAll()
        updateTrailDisplay()
    }

    // 创建母船爆炸效果
    private func createMotherShipExplosion(at position: CGPoint) {
        // 创建爆炸粒子效果
        let explosion = SKNode()
        explosion.position = position
        
        // 创建多个爆炸粒子
        for _ in 0..<20 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            particle.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.1, alpha: 1.0)
            particle.strokeColor = SKColor.clear
            
            // 随机位置
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let distance = CGFloat.random(in: 0...30)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            particle.position = CGPoint(x: dx, y: dy)
            
            // 添加动画
            let move = SKAction.moveBy(x: dx * 2, y: dy * 2, duration: 0.5)
            let scale = SKAction.scale(to: 0.1, duration: 0.5)
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let group = SKAction.group([move, scale, fade])
            let remove = SKAction.removeFromParent()
            
            particle.run(SKAction.sequence([group, remove]))
            explosion.addChild(particle)
        }
        
        // 添加闪光效果
        let flash = SKShapeNode(circleOfRadius: 50)
        flash.fillColor = SKColor.white
        flash.strokeColor = SKColor.clear
        flash.alpha = 0.8
        explosion.addChild(flash)
        
        // 闪光动画
        let flashFade = SKAction.fadeOut(withDuration: 0.2)
        let flashRemove = SKAction.removeFromParent()
        flash.run(SKAction.sequence([flashFade, flashRemove]))
        
        addChild(explosion)
    }
    
    // 创建飞船碰撞效果
    private func createShipCollisionEffect(at position: CGPoint) {
        // 创建碰撞粒子效果
        let collision = SKNode()
        collision.position = position
        
        // 创建多个碰撞粒子
        for _ in 0..<10 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
            particle.fillColor = SKColor(red: 0.3, green: 0.8, blue: 0.9, alpha: 1.0)
            particle.strokeColor = SKColor.clear
            
            // 随机位置
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let distance = CGFloat.random(in: 0...20)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            particle.position = CGPoint(x: dx, y: dy)
            
            // 添加动画
            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.3)
            let fade = SKAction.fadeOut(withDuration: 0.3)
            let group = SKAction.group([move, fade])
            let remove = SKAction.removeFromParent()
            
            particle.run(SKAction.sequence([group, remove]))
            collision.addChild(particle)
        }
        
        addChild(collision)
    }

    // 实现碰撞检测代理方法
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB

        // 检查是否是陨石与陨石的碰撞
        if (bodyA.categoryBitMask == asteroidCategory && bodyB.categoryBitMask == asteroidCategory) {
            // 获取碰撞的两个陨石
            let asteroid1 = bodyA.node as? SKSpriteNode
            let asteroid2 = bodyB.node as? SKSpriteNode
            
            // 计算碰撞点的法线向量
            let contactPoint = contact.contactPoint
            let dx = contactPoint.x - (asteroid1?.position.x ?? 0)
            let dy = contactPoint.y - (asteroid1?.position.y ?? 0)
            let distance = sqrt(dx * dx + dy * dy)
            let normalizedDx = dx / distance
            let normalizedDy = dy / distance
            
            // 为两个陨石应用反弹力
            let bounceForce: CGFloat = 1.0
            asteroid1?.physicsBody?.applyImpulse(CGVector(
                dx: -normalizedDx * bounceForce,
                dy: -normalizedDy * bounceForce
            ))
            asteroid2?.physicsBody?.applyImpulse(CGVector(
                dx: normalizedDx * bounceForce,
                dy: normalizedDy * bounceForce
            ))
            
            // 创建碰撞效果
            createBounceEffect(at: contactPoint)
        }

        // 检查是否是飞船与边界的碰撞
        if (bodyA.categoryBitMask == playerCategory && bodyB.categoryBitMask == borderCategory) ||
           (bodyA.categoryBitMask == borderCategory && bodyB.categoryBitMask == playerCategory) {
            // 创建碰撞效果
            let contactPoint = contact.contactPoint
            createBounceEffect(at: contactPoint)
            // 播放碰撞音效
            AudioManager.shared.playSoundEffect("shipCollision", in: self)
        }

        // 检查是否是飞船与母舰的碰撞
        if (bodyA.categoryBitMask == playerCategory && bodyB.categoryBitMask == motherShipCategory) ||
           (bodyA.categoryBitMask == motherShipCategory && bodyB.categoryBitMask == playerCategory) {
            // 创建碰撞效果
            let contactPoint = contact.contactPoint
            
            // 播放母船爆炸音效
            AudioManager.shared.playSoundEffect("mothershipExplosion", in: self)
            
            // 为母船添加爆炸效果
            if let motherShip = motherShip {
                // 创建爆炸效果
                createMotherShipExplosion(at: motherShip.position)
                
                // 母船震荡效果
                let shake = SKAction.sequence([
                    SKAction.moveBy(x: 10, y: 0, duration: 0.05),
                    SKAction.moveBy(x: -20, y: 0, duration: 0.1),
                    SKAction.moveBy(x: 10, y: 0, duration: 0.05)
                ])
                
                // 母船发光效果
                let flash = SKAction.sequence([
                    SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.1),
                    SKAction.colorize(with: .white, colorBlendFactor: 0.0, duration: 0.1)
                ])
                
                // 创建缩放效果
                let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
                let scaleDown = SKAction.scale(to: 0.1, duration: 0.3)
                let fadeOut = SKAction.fadeOut(withDuration: 0.3)
                let remove = SKAction.removeFromParent()
                
                // 组合所有动画
                let animationGroup = SKAction.group([shake, flash, scaleUp])
                let finalSequence = SKAction.sequence([
                    animationGroup,
                    SKAction.group([scaleDown, fadeOut]),
                    remove
                ])
                
                // 执行动画序列
                motherShip.run(finalSequence) { [weak self] in
                    // 动画完成后移除母船
                    self?.motherShip?.removeFromParent()
                    self?.motherShip = nil
                    
                    // 显示关卡完成界面
                    self?.isLevelCompleted = true
//                    self?.showLevelCompleteMenu()
                    self?.startNextLevel()
                }
            }
            
            // 为玩家飞船添加碰撞效果
            createShipCollisionEffect(at: contactPoint)
            // 播放飞船碰撞音效
            AudioManager.shared.playSoundEffect("shipCollision", in: self)
            
            // 为玩家飞船添加回弹效果
            if let playerVelocity = playerShip.physicsBody?.velocity {
                // 计算回弹方向
                let dx = contactPoint.x - playerShip.position.x
                let dy = contactPoint.y - playerShip.position.y
                let distance = sqrt(dx * dx + dy * dy)
                let normalizedDx = dx / distance
                let normalizedDy = dy / distance
                
                // 应用回弹力
                let bounceForce: CGFloat = 200.0
                playerShip.physicsBody?.applyImpulse(CGVector(
                    dx: -normalizedDx * bounceForce,
                    dy: -normalizedDy * bounceForce
                ))
            }
            // 重置轨迹
            resetTrail()
        }

        // 检查是否是飞船与陨石的碰撞
        if (bodyA.categoryBitMask == playerCategory && bodyB.categoryBitMask == asteroidCategory) ||
           (bodyA.categoryBitMask == asteroidCategory && bodyB.categoryBitMask == playerCategory) {
            // 创建碰撞效果
            let contactPoint = contact.contactPoint
            createShipCollisionEffect(at: contactPoint)
            // 播放飞船碰撞音效
            AudioManager.shared.playSoundEffect("shipCollision", in: self)
            
            // 计算反弹方向
            let dx = contactPoint.x - playerShip.position.x
            let dy = contactPoint.y - playerShip.position.y
            let distance = sqrt(dx * dx + dy * dy)
            let normalizedDx = dx / distance
            let normalizedDy = dy / distance
            
            // 应用回弹力
            let bounceForce: CGFloat = 50.0
            playerShip.physicsBody?.applyImpulse(CGVector(
                dx: -normalizedDx * bounceForce,
                dy: -normalizedDy * bounceForce
            ))
            // 重置轨迹
            // resetTrail()
        }

        // 检查是否是母船与陨石的碰撞
        if (bodyA.categoryBitMask == motherShipCategory && bodyB.categoryBitMask == asteroidCategory) ||
           (bodyA.categoryBitMask == asteroidCategory && bodyB.categoryBitMask == motherShipCategory) {
            // 移除碰撞处理逻辑
        }
    }

    // 创建碰撞效果
    private func createBounceEffect(at position: CGPoint) {
        // 创建一个简单的粒子效果
        for _ in 0..<10 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
            particle.fillColor = SKColor.white
            particle.strokeColor = SKColor.clear
            particle.position = position
            particle.alpha = 0.7
            addChild(particle)

            // 随机方向
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let distance = CGFloat.random(in: 10...30)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            // 添加动画
            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.3)
            let fade = SKAction.fadeOut(withDuration: 0.3)
            let group = SKAction.group([move, fade])
            let remove = SKAction.removeFromParent()

            particle.run(SKAction.sequence([group, remove]))
        }
    }

    // 游戏结束方法
    private func endGame() {
        if gameState != .playing { return }

        // 切换游戏状态
        gameState = .gameOver
        print("游戏结束，状态已设置为：\(gameState)")

        // 保存当前关卡
        LevelManager.shared.saveLevel(currentLevel)

        // 显示游戏结束菜单
        showGameOverMenu()
    }

    // 显示游戏结束界面
    private func showGameOverMenu() {
        // 创建游戏结束标签
        let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.text = "游戏结束"
        gameOverLabel.fontSize = 60
        gameOverLabel.position = CGPoint(x: size.width/2, y: size.height * 0.7)
        gameOverLabel.zPosition = 10
        addChild(gameOverLabel)

        // 创建重新开始按钮
        let restartButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 10)
        restartButton.fillColor = SKColor(red: CGFloat.random(in: 0...1),
                                          green: CGFloat.random(in: 0...1),
                                          blue: CGFloat.random(in: 0...1),
                                          alpha: 0.8)
        
        restartButton.position = CGPoint(x: size.width/2, y: size.height * 0.4)
        restartButton.name = "restartButton"
        restartButton.zPosition = 10

        let restartLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        restartLabel.text = "重新开始"
        restartLabel.fontSize = 30
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: 0, y: -3)
        restartLabel.verticalAlignmentMode = .center
        restartLabel.horizontalAlignmentMode = .center
        restartButton.addChild(restartLabel)

        addChild(restartButton)

        // 创建返回主页按钮
        let menuButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 10)
        menuButton.fillColor = SKColor(red: CGFloat.random(in: 0...1),
                                          green: CGFloat.random(in: 0...1),
                                          blue: CGFloat.random(in: 0...1),
                                          alpha: 0.8)
        menuButton.position = CGPoint(x: size.width/2, y: size.height * 0.3)
        menuButton.name = "menuButton"
        menuButton.zPosition = 10

        let menuLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        menuLabel.text = "返回主页"
        menuLabel.fontSize = 30
        menuLabel.fontColor = .white
        menuLabel.position = CGPoint(x: 0, y: -3)
        menuLabel.verticalAlignmentMode = .center
        menuLabel.horizontalAlignmentMode = .center
        menuButton.addChild(menuLabel)

        addChild(menuButton)
    }

    // 处理游戏结束界面的按钮点击
    private func handleGameOverTouches(at location: CGPoint) {
        let nodes = self.nodes(at: location)
        for node in nodes {
            if node.name == "restartButton" {
                // 点击效果
                let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
                let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                let clickSequence = SKAction.sequence([scaleUp, scaleDown])
                node.run(clickSequence)

                // 延迟重新开始当前关卡
                let wait = SKAction.wait(forDuration: 0.2)
                let restart = SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let gameScene = GameScene(size: self.size)
                    gameScene.scaleMode = self.scaleMode
                    gameScene.currentLevel = self.currentLevel
                    let transition = SKTransition.fade(withDuration: 0.5)
                    self.view?.presentScene(gameScene, transition: transition)
                }
                run(SKAction.sequence([wait, restart]))
                return
            } else if node.name == "menuButton" {
                // 点击效果
                let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
                let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                let clickSequence = SKAction.sequence([scaleUp, scaleDown])
                node.run(clickSequence)

                // 返回主菜单
                let wait = SKAction.wait(forDuration: 0.2)
                let goToMenu = SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let menuScene = MainMenuScene(size: self.size)
                    menuScene.scaleMode = self.scaleMode
                    let transition = SKTransition.fade(withDuration: 0.5)
                    self.view?.presentScene(menuScene, transition: transition)
                }
                run(SKAction.sequence([wait, goToMenu]))
                return
            }
        }
    }

    // 创建陨石
    private func createAsteroids() {
        // 计算当前关卡的陨石数量（从第三关开始，每两关增加一个，最多5个）
        let asteroidCount = min(4, max(1, (currentLevel - 2) / 2))
        
        // 清除现有的陨石
        for asteroid in asteroids {
            asteroid.removeFromParent()
        }
        asteroids.removeAll()
        asteroidVelocities.removeAll()
        lastAsteroidDirectionChangeTime.removeAll()
        
        // 创建新的陨石
        for _ in 0..<asteroidCount {
            // 随机大小（玩家飞船的1-1.5倍）
            let baseSize = CGFloat.random(in: 40...60)
            let asteroid = SKSpriteNode()
            asteroid.size = CGSize(width: baseSize, height: baseSize)
            
            // 设置陨石的层级
            asteroid.zPosition = 1 // 确保陨石在母船下方
            
            // 创建不规则形状
            let path = createIrregularPath(size: baseSize)
            let shape = SKShapeNode(path: path)
            shape.fillColor = SKColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
            shape.strokeColor = SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
            shape.lineWidth = 2
            asteroid.addChild(shape)
            
            // 随机位置（避免与母船和玩家飞船重叠，且不低于玩家出生位置）
            let margin: CGFloat = baseSize
            let playerSpawnAreaHeight: CGFloat = size.height * 0.3
            let randomX = CGFloat.random(in: margin...(size.width - margin))
            let randomY = CGFloat.random(in: (playerSpawnAreaHeight + margin)...(size.height - margin))
            asteroid.position = CGPoint(x: randomX, y: randomY)
            
            // 设置物理体
            asteroid.physicsBody = SKPhysicsBody(polygonFrom: path)
            asteroid.physicsBody?.isDynamic = true
            asteroid.physicsBody?.affectedByGravity = false
            asteroid.physicsBody?.categoryBitMask = asteroidCategory
            asteroid.physicsBody?.contactTestBitMask = playerCategory | borderCategory | asteroidCategory
            asteroid.physicsBody?.collisionBitMask = borderCategory | asteroidCategory
            asteroid.physicsBody?.restitution = 1.0
            asteroid.physicsBody?.linearDamping = 0.0
            asteroid.name = "asteroid"
            
            // 设置初始随机方向
            let randomAngle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let speed = baseAsteroidSpeed * (1.0 + CGFloat(currentLevel - 3) * 0.05)
            let velocity = CGVector(
                dx: cos(randomAngle) * speed,
                dy: sin(randomAngle) * speed
            )
            
            addChild(asteroid)
            asteroids.append(asteroid)
            asteroidVelocities.append(velocity)
            lastAsteroidDirectionChangeTime.append(0)
        }
    }
    
    // 创建不规则路径
    private func createIrregularPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let points = 16 // 增加不规则形状的点数
        let radius = size / 2
        
        path.move(to: CGPoint(x: radius, y: 0))
        
        for i in 1..<points {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(points)
            let randomRadius = radius * CGFloat.random(in: 0.7...1.3)
            let x = cos(angle) * randomRadius
            let y = sin(angle) * randomRadius
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.closeSubpath()
        return path
    }

}
