//
//  AnalyzerScene.swift
//  Go
//
//  Created by Jae Seung Lee on 1/24/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import SpriteKit

class AnalyzerScene: SKScene {
    
    var scale: CGFloat
    var boardSize = 19
    
    var goBoard: SKSpriteNode?
    var analyzerBoard: SKSpriteNode?
    var blackStone: SKShapeNode?
    var whiteStone: SKShapeNode?
    //var positionNode: SKShapeNode?
    var blueSpot: SKShapeNode?
    var yellowSpot: SKShapeNode?
    var territorySpot: SKShapeNode?
    
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        scale = size.height / 450.0 * 0.7
        
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
    
    convenience init(size: CGSize, boardSize: Int = 19) {
        self.init(size: size)
        self.boardSize = boardSize
    }
    
    override func didMove(to view: SKView) {
        // Get label node from scene and store it for use later
        
        self.goBoard = SKSpriteNode(color: .clear, size: CGSize(width: scale * 420, height: scale * 450))
        self.goBoard!.zPosition = -30
        self.addChild(self.goBoard!)
        
        self.analyzerBoard = SKSpriteNode(color: .clear, size: CGSize(width: scale * 420, height: scale * 450))
        self.analyzerBoard!.zPosition = -10
        self.addChild(self.analyzerBoard!)
 
        for row in 0..<boardSize {
            for column in 0..<boardSize {
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
        self.blueSpot = SKShapeNode.init(circleOfRadius: scale * 0.5 * 22.119)
        self.yellowSpot = SKShapeNode.init(circleOfRadius: scale * 0.5 * 22.119)
        self.territorySpot = SKShapeNode.init(circleOfRadius: scale * 0.25 * 22.119)
    }
}
