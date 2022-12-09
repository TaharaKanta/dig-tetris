//
//  GameScene.swift
//  sumpleTetris2
//
//  Created by user on 2022/12/05.
//

import SpriteKit

let TickLengthLevelOne = TimeInterval(100)

let BlockSize: CGFloat = 20.0

let NumColumns = 10
let NumRows = 20


class GameScene: SKScene {
    var tick:(() -> ())?
    var tickLengthMillisec = TickLengthLevelOne
    var lastTick:NSDate?
    
    let LayerPosition = CGPoint(x: 6, y: -6)
    
    var shapeLayer = SKNode()
    
    var textureCache = Dictionary<String, SKTexture>()
    
    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor.blue//背景色変更
    }
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?

    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoder not supported")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        let background = SKSpriteNode(texture:SKTexture(imageNamed: "background"), size:CGSize(width: UIScreen.main.bounds.width - 100, height: UIScreen.main.bounds.height))
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(background)
        
        let gameBoard = SKSpriteNode(texture: SKTexture(imageNamed: "gameboard"), size: CGSize(width: BlockSize * CGFloat(NumColumns), height: BlockSize * CGFloat(NumRows)))
        
        gameBoard.zPosition = 2.0
        
        shapeLayer.position = CGPoint(x: -BlockSize * CGFloat(NumColumns)/2, y: BlockSize * CGFloat(NumRows)/2)
        shapeLayer.zPosition = 2.5
        gameBoard.addChild(shapeLayer)
        background.addChild(gameBoard)
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        guard let lastTick = lastTick else {
            return
        }
        let timePassed = lastTick.timeIntervalSinceNow * -1000.0
        if timePassed > tickLengthMillisec {
            self.lastTick = NSDate()
            tick?()
        }
    }
    
    func startTimer() {
        
        lastTick = NSDate()
    }
    
    func stopTimer() {
        
        lastTick = nil
    }
    
    func pointForColumn(column: Int, row: Int) -> CGPoint {
        let x =  ((CGFloat(column) * BlockSize) + (BlockSize / 2))
        let y =  -((CGFloat(row) * BlockSize) + (BlockSize / 2))

        return CGPoint(x: x, y: y)
    }
    
    func addPreviewShapeToScene(shape: Shape, completion: @escaping () -> ()) {
        
        for block in shape.blocks {
            var texture = textureCache[block.spriteName]
            
            if texture == nil {
                texture = SKTexture(imageNamed: block.spriteName)
                textureCache[block.spriteName] = texture
            }
            let sprite = SKSpriteNode(texture: texture)
            
            sprite.position = pointForColumn(column: block.column, row: block.row - 2)
            sprite.zPosition = 3.0
            shapeLayer.addChild(sprite)
            block.sprite = sprite
            sprite.alpha = 0.0
            
            let moveAction = SKAction.move(to: pointForColumn(column: block.column, row: block.row), duration: TimeInterval(0.2))
            let fadeInAction = SKAction.fadeAlpha(to: 0.7, duration: 0.4)
            fadeInAction.timingMode = .easeOut
            sprite.run(SKAction.group([moveAction, fadeInAction]))
        }
        run(SKAction.wait(forDuration: 0.4), completion: completion)
    }
    
    func movePreviewShape(shape: Shape, completion: @escaping () -> ()) {
        
        for block in shape.blocks {
            let sprite = block.sprite!
            let moveTo = pointForColumn(column: block.column, row: block.row)
            let moveToAction: SKAction = SKAction.move(to: moveTo, duration: 0.2)
            moveToAction.timingMode = .easeOut
            sprite.run(SKAction.group([moveToAction, SKAction.fadeAlpha(to: 1.0, duration: 0.2)]), completion: {})
        }
        run(SKAction.wait(forDuration: 0.2), completion: completion)
    }
    
    func redrawShape(shape: Shape, completion: @escaping () -> ()) {
        for block in shape.blocks {
            let sprite = block.sprite!
            let moveTo = pointForColumn(column: block.column, row: block.row)
            let moveToAction: SKAction = SKAction.move(to: moveTo, duration: 0.05)
            moveToAction.timingMode = .easeOut
            if block == shape.blocks.last {
                sprite.run(moveToAction, completion: completion)
            } else {
                sprite.run(moveToAction)
            }
        }
    }
    
    func collapsingLines(linesToRemove: Array<Array<Block>>, fallenBlocks: Array<Array<Block>>, completion:@escaping () -> ()) {
        
        var longestDuration: TimeInterval = 0
        
        for (columnIdx, column) in fallenBlocks.enumerated() {
            for (blockIdx, block) in column.enumerated() {
                let newPosition = pointForColumn(column: block.column, row: block.row)
                let sprite = block.sprite!

                let delay = (TimeInterval(columnIdx) * 0.05) + (TimeInterval(blockIdx) * 0.05)
                let duration = TimeInterval(((sprite.position.y - newPosition.y) / BlockSize) * 0.05)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        moveAction
                        ])
                )

                longestDuration = max(longestDuration, duration + delay)
            }
        }
        
        for rowToRemove in linesToRemove {
            for block in rowToRemove {
                let randomRadius = CGFloat(UInt(arc4random_uniform(400) + 100))
                let goLeft = arc4random_uniform(100) % 2 == 0
                
                var point = pointForColumn(column: block.column, row: block.row)
                point = CGPoint(x: point.x + (goLeft ? -randomRadius: randomRadius), y: point.y)
                let randomDuration = TimeInterval(arc4random_uniform(2)) + 0.5
                
                var startAngle = CGFloat(Double.pi)
                var endAngle = startAngle * 2
                if goLeft {
                    endAngle = startAngle
                    startAngle = 0
                }
                let archPath = UIBezierPath(arcCenter: point, radius: randomRadius, startAngle: startAngle, endAngle: endAngle, clockwise: goLeft)
                let archAction = SKAction.follow(archPath.cgPath, asOffset: false, orientToPath: true, duration: randomDuration)
                archAction.timingMode = .easeIn
                
                let sprite = block.sprite!
                
                sprite.zPosition = 100
                sprite.run(SKAction.sequence([SKAction.removeFromParent()]))
            }
        }
        
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
}


