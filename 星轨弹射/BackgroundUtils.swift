import SpriteKit

class BackgroundUtils {
    static func createStarryBackground(in scene: SKScene) {
        // 增加星星数量sdadasa
        for _ in 0..<200 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2.0))
            star.fillColor = SKColor.white
            star.strokeColor = SKColor.clear
            
            // 星星随机分布在屏幕各处，包括屏幕上方和下方
            let yPosition = CGFloat.random(in: -scene.size.height...scene.size.height * 2)
            star.position = CGPoint(
                x: CGFloat.random(in: 0...scene.size.width),
                y: yPosition
            )
            star.alpha = CGFloat.random(in: 0.2...1.0)
            star.name = "star"
            scene.addChild(star)

            // 添加闪烁动画
            let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: CGFloat.random(in: 0.5...2.0))
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: CGFloat.random(in: 0.5...2.0))
            let blinkSequence = SKAction.sequence([fadeOut, fadeIn])
            let blinkForever = SKAction.repeatForever(blinkSequence)
            
            // 添加移动动画，使用更随机的速度
            let moveDuration = TimeInterval.random(in: 3...15) // 更宽的速度范围
            let moveDown = SKAction.moveBy(x: 0, y: -scene.size.height * 3, duration: moveDuration)
            let resetPosition = SKAction.run { [weak star, weak scene] in
                guard let scene = scene, let star = star else { return }
                // 重新设置星星位置到屏幕顶部
                star.position = CGPoint(
                    x: CGFloat.random(in: 0...scene.size.width),
                    y: scene.size.height + CGFloat.random(in: 0...scene.size.height)
                )
            }
            let moveSequence = SKAction.sequence([moveDown, resetPosition])
            let moveForever = SKAction.repeatForever(moveSequence)
            
            // 同时执行闪烁和移动动画
            star.run(SKAction.group([blinkForever, moveForever]))
        }
    }
} 
