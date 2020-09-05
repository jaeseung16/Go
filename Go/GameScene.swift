//
//  GameScene.swift
//  Go
//
//  Created by Jae Seung Lee on 8/4/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    var count = 0
    var scale: CGFloat
    
    var goBoard: SKSpriteNode?
    var gameBoard: SKSpriteNode?
    var analyzerBoard: SKSpriteNode?
    var blackStone: SKShapeNode?
    var whiteStone: SKShapeNode?
    var positionNode: SKShapeNode?
    
    let goBoardTexture = SKTexture(imageNamed: "GoBoard")
    let blackStoneTexture = SKTexture(imageNamed: "BlackStone")
    let whiteStoneTexture = SKTexture(imageNamed: "WhiteStone")
    let topLeftTexture = SKTexture(imageNamed: "TopLeft")
    let topTexture = SKTexture(imageNamed: "Top")
    let topRightTexture = SKTexture(imageNamed: "TopRight")
    let bottomLeftTexture = SKTexture(imageNamed: "BottomLeft")
    let bottomTexture = SKTexture(imageNamed: "Bottom")
    let bottomRightTexture = SKTexture(imageNamed: "BottomRight")
    let leftTexture = SKTexture(imageNamed: "Left")
    let rightTexture = SKTexture(imageNamed: "Right")
    let middleTexture = SKTexture(imageNamed: "Middle")
    let starPointTexture = SKTexture(imageNamed: "StarPoint")
    
    var gameDelegate: GameDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        scale = size.height / 450.0 * 0.7
        
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
    
    override func didMove(to view: SKView) {
        // Get label node from scene and store it for use later
        //self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        //if let label = self.label {
        //    label.alpha = 0.0
        //    label.run(SKAction.fadeIn(withDuration: 2.0))
        //}
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
        
        //self.goBoard = SKShapeNode.init(rectOf: CGSize(width: scale * 420, height: scale * 450))
        /*
        self.goBoard = SKSpriteNode(texture: goBoardTexture, size: CGSize(width: scale * 420, height: scale * 450))
        if let node = self.goBoard?.copy() as! SKSpriteNode? {
            //node.fillColor = SKColor.yellow
            //node.fillTexture = goBoardTexture
            node.zPosition = -10
            self.addChild(node)
        }
        */
        
        self.goBoard = SKSpriteNode(color: .clear, size: CGSize(width: scale * 420, height: scale * 450))
        self.goBoard!.zPosition = -30
        self.addChild(self.goBoard!)
        
        self.gameBoard = SKSpriteNode(color: .clear, size: CGSize(width: scale * 420, height: scale * 450))
        self.gameBoard!.zPosition = -20
        self.addChild(self.gameBoard!)
        
        self.analyzerBoard = SKSpriteNode(color: .clear, size: CGSize(width: scale * 420, height: scale * 450))
        self.analyzerBoard!.zPosition = -10
        self.addChild(self.analyzerBoard!)
        
        /*
        if let node = self.goBoard?.copy() as! SKSpriteNode? {
            //node.fillColor = SKColor.yellow
            //node.fillTexture = goBoardTexture
            node.zPosition = -10
            self.addChild(node)
            print("\(node)")
        }
        */
 
        for row in 0..<19 {
            for column in 0..<19 {
                let intersection = SKShapeNode(rect: CGRect(x: 0, y: 0, width: CGFloat(Float(scale) * 420 / 19 + 1), height: CGFloat(Float(scale) * 450 / 19) + 1))
                
                print("\(intersection.frame.size)")
                
                let xPos = Float(column) * Float(scale) * 420 / 19 - Float(scale) * 210
                let yPos = Float(row) * Float(scale) * 450 / 19 - Float(scale) * 225
                
                intersection.position = CGPoint(x: CGFloat(xPos), y: CGFloat(yPos))
                intersection.zPosition = -25
                intersection.lineWidth = 0
                intersection.strokeColor = .orange
                
                if row == 0 {
                    if column == 0 {
                        intersection.fillTexture = bottomLeftTexture
                    } else if column == 18 {
                        intersection.fillTexture = bottomRightTexture
                    } else {
                        intersection.fillTexture = bottomTexture
                    }
                } else if row == 18 {
                    if column == 0 {
                        intersection.fillTexture = topLeftTexture
                    } else if column == 18 {
                        intersection.fillTexture = topRightTexture
                    } else {
                        intersection.fillTexture = topTexture
                    }
                } else if column == 0 {
                    intersection.fillTexture = leftTexture
                } else if column == 18 {
                    intersection.fillTexture = rightTexture
                } else if row == 3 || row == 9 || row == 15 {
                    if column == 3 || column == 9 || column == 15 {
                        intersection.fillTexture = starPointTexture
                    } else {
                        intersection.fillTexture = middleTexture
                    }
                } else {
                    intersection.fillTexture = middleTexture
                }
                intersection.fillColor = .white
                
                goBoard!.addChild(intersection)
                
                intersection.isHidden = false
                
                print("row = \(row), column = \(column): \(intersection)")
            }
        }
        
        
        self.whiteStone = SKShapeNode.init(circleOfRadius: scale * 0.5 * 21.810)
        self.blackStone = SKShapeNode.init(circleOfRadius: scale * 0.5 * 22.119)
        
    }
    
    private func pointFor(column: Int, row: Int) -> CGPoint {
        let intersectionWitdh: Float = Float(scale) * 420 / 19
        let intersectionHeight: Float = Float(scale) * 450 / 19
        
        return CGPoint(
            x: CGFloat(Float(column) * intersectionWitdh - Float(scale) * 210 + 0.5 * intersectionWitdh),
            y: CGFloat(Float(19 - row) * intersectionHeight - Float(scale) * 225 + 0.5 * intersectionHeight))
    }
    
    private func convertPoint(_ point: CGPoint) -> (success: Bool, column: Int, row: Int) {
        var success = true
        var row: Int = 0
        var column: Int = 0
        
        let intersectionWitdh: Float = Float(scale) * 420 / 19
        let intersectionHeight: Float = Float(scale) * 450 / 19
        
        if point.x >= -1.0 * scale * 210 && point.x < scale * 210 {
            column = Int((Float(point.x) + Float(scale) * 210.0) / intersectionWitdh)
        } else {
            success = false
        }
        
        if point.y >= -1.0 * scale * 225 && point.y < scale * 225 {
            row = 19 - Int((Float(point.y) + Float(scale) * 225.0) / intersectionHeight)
        } else {
            success = false
        }
        
        return (success, column, row)
    }
    
    func touchDown(atPoint pos : CGPoint) {
        
        var success: Bool
        var column: Int
        var row: Int
        (success, column, row) = convertPoint(pos)
        
        guard let isPlayable = gameDelegate?.isPlayable(stone: count % 2 == 0 ? .White : .Black, column: column, row: row), isPlayable else {
            print("Illegal play!")
            return
        }
        
        let node = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
        node.position = pointFor(column: column, row: row)
        node.fillColor = count % 2 == 0 ? .black : .white
        self.gameBoard!.addChild(node)
        
        positionNode = node
        
        print("\(String(describing: positionNode))")
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        guard let node = positionNode else {
            return
        }
        
        var success: Bool
        var column: Int
        var row: Int
        (success, column, row) = convertPoint(pos)
        
        guard let isPlayable = gameDelegate?.isPlayable(stone: count % 2 == 0 ? .White : .Black, column: column, row: row), isPlayable else {
            print("Illegal play!")
            return
        }
        
        node.position = pointFor(column: column, row: row)
        
        print("\(String(describing: positionNode))")
    }
    
    func touchUp(atPoint pos : CGPoint) {
        print("pos = \(pos)")
        var success: Bool
        var column: Int
        var row: Int
        (success, column, row) = convertPoint(pos)
        print("success = \(success), column = \(column), row = \(row)")
        
        guard let node = positionNode else {
            return
        }
        
        self.removeChildren(in: [node])
        positionNode = nil
        
        print("\(String(describing: positionNode))")
        
        guard let isPlayable = gameDelegate?.isPlayable(stone: count % 2 == 0 ? .White : .Black, column: column, row: row), isPlayable else {
            print("Illegal play!")
            return
        }
        
        gameDelegate?.play(stone: count % 2 == 0 ? .White : .Black, column: column, row: row)

        let font = NSFont.systemFont(ofSize: (count > 99 ? 18 : 24))
        
        let sequence = SKLabelNode(fontNamed: font.fontName)
        sequence.name = "sequence"
        sequence.text = "\(count)"
        sequence.fontSize = font.pointSize
        sequence.verticalAlignmentMode = .center
        
       
        if count % 2 == 0 {
            if let node = self.whiteStone?.copy() as! SKShapeNode? {
                node.name = "\(count)"
                node.position = pointFor(column: column, row: row)
                node.lineWidth = 0
                node.fillColor = SKColor.black
                node.fillTexture = blackStoneTexture
                
                sequence.fontColor = .white
                sequence.position = CGPoint(x: 0.0, y: 0.0)
                
                node.addChild(sequence)
                self.gameBoard!.addChild(node)
            }
        } else {
            if let node = self.blackStone?.copy() as! SKShapeNode? {
                node.name = "\(count)"
                node.position = pointFor(column: column, row: row)
                node.lineWidth = 0
                node.fillColor = SKColor.white
                node.fillTexture = whiteStoneTexture
                
                sequence.fontColor = .black
                sequence.position = CGPoint(x: 0.0, y: 0.0)
                
                node.addChild(sequence)
                self.gameBoard!.addChild(node)
            }
        }
        
        count += 1
    }
    
    override func mouseDown(with event: NSEvent) {
        self.touchDown(atPoint: event.location(in: self))
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.touchMoved(toPoint: event.location(in: self))
    }
    
    override func mouseUp(with event: NSEvent) {
        self.touchUp(atPoint: event.location(in: self))
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 0x31:
            if let label = self.label {
                label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
            }
        default:
            print("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }
    
    func hide(number: Int) -> Bool {
        if let node = gameBoard?.childNode(withName: "\(number)") {
            node.isHidden = true
            return true
        }
        return false
    }
    
    func show(number: Int) -> Bool {
        if let node = gameBoard?.childNode(withName: "\(number)") {
            node.isHidden = false
            return true
        }
        return false
    }
    
    func showSequence() -> Void {
        guard let children = gameBoard?.children else {
            print("The scene has no children: scene = \(String(describing: scene))")
            return
        }
        
        for child in children {
            guard let sequence = child.childNode(withName: "sequence") else {
                print("The node has no sequence: node = \(child)")
                continue
            }
            
            sequence.isHidden = !sequence.isHidden
        }
        
    }
    
    func showAnalysis() -> Void {
        analyzerBoard?.removeAllChildren()
        
        for row in 0..<19 {
            for column in 0..<19 {
                guard let isPlayable = gameDelegate?.isPlayable(stone: count % 2 == 0 ? .White : .Black, column: column, row: row), isPlayable else {
                    print("Illegal play!")
                    continue
                }
            
                let font = NSFont.systemFont(ofSize: (count > 99 ? 18 : 24))
                
                let analysis = SKLabelNode(fontNamed: font.fontName)
                analysis.position = pointFor(column: column, row: row)
                analysis.name = "analysis"
                analysis.text = "\(count)"
                analysis.fontSize = font.pointSize
                analysis.fontColor = count % 2 == 0 ? .black : .white
                analysis.verticalAlignmentMode = .center
                
                
                analyzerBoard?.addChild(analysis)
                
                analysis.isHidden = false
                
                print("row = \(row), column = \(column): \(analysis)")
            }
        }
    }
    
    func hideAnalysis() -> Void {
        analyzerBoard?.removeAllChildren()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        gameDelegate?.updateClock(currentTime)
        
        if let delegate = gameDelegate, delegate.needToShowAnalysis() {
            showAnalysis()
        } else {
            hideAnalysis()
        }

    }
}
