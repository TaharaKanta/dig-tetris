//
//  GameViewController.swift
//  sumpleTetris2
//
//  Created by user on 2022/12/05.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController, GameLogicDelegate{
    
    func gameShapeDidLand(gameLogic: GameLogic) {
        
        scene.stopTimer()
        self.view.isUserInteractionEnabled = false
        let removedLines = gameLogic.removeCompletedLines()
        
        if removedLines.linesRemoved.count > 0 {
            scene.collapsingLines(linesToRemove: removedLines.linesRemoved, fallenBlocks: removedLines.fallenBlocks) {
                self.gameShapeDidLand(gameLogic: gameLogic)
            }
        } else {
            nextShape()
        }
    }
    
    func gameShapeDidMove(gameLogic: GameLogic) {
        scene.redrawShape(shape: gameLogic.fallingShape!) {}
    }
    
    var scene: GameScene!
    var gameLogic: GameLogic!
    
    var panPointNow: CGPoint?

    override func viewDidLoad() {
        
        super.viewDidLoad()

        if let view = self.view as! SKView? {
            view.isMultipleTouchEnabled = false
            scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            view.presentScene(scene)
            
            scene.tick = didTick
            
            gameLogic = GameLogic()
            gameLogic.delegate = self
            gameLogic.startGame()
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    @IBAction func didTap(_ sender:UITapGestureRecognizer){
        gameLogic.rotateShape()
    }
    
    @IBAction func didPan(_ sender: UIPanGestureRecognizer) {
        
        let currentPoint = sender.translation(in: self.view)
        
        if let originalPoint = panPointNow {
            if abs(currentPoint.x - originalPoint.x) > (BlockSize * 1.0) {
                if sender.velocity(in: self.view).x > CGFloat(0) {
                    gameLogic.moveShapeRight()
                    panPointNow = currentPoint
                } else {
                    gameLogic.moveShapeLeft()
                    panPointNow = currentPoint
                }
            }
        } else if sender.state == .began {
            panPointNow = currentPoint
        }
        
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith ohterGestureRecognizer: UIGestureRecognizer)-> Bool{
        return true
    }
    

    
    func gameDidStart(gameLogic: GameLogic) {
        
        scene.tickLengthMillisec = TickLengthLevelOne
        if gameLogic.nextShape != nil && gameLogic.nextShape!.blocks[0].sprite == nil {
            scene.addPreviewShapeToScene(shape: gameLogic.nextShape!) {
                self.nextShape()
            }
        } else {
            nextShape()
        }
    }
    
    func didTick() {
        gameLogic.letShapeFall()
    }
    
    func nextShape() {
        
        let newShapes = gameLogic.newShape()
        guard let fallingShape = newShapes.fallingShape else {
            return
        }
        self.scene.addPreviewShapeToScene(shape: newShapes.nextShape!) {}
        self.scene.movePreviewShape(shape: fallingShape) {
            self.view.isUserInteractionEnabled = true
            self.scene.startTimer()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
