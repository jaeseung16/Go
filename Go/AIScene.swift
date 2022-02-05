//
//  AIScene.swift
//  Go
//
//  Created by Jae Seung Lee on 2/3/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import SpriteKit

class AIScene: SKScene {
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
    
    var sceneDelegate: AISceneDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        scale = size.height / 450.0 * 0.8
        
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
    
    func clear() -> Void {
        analyzerBoard?.removeAllChildren()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let delegate = sceneDelegate, let analysis = delegate.getAnalysis(), let feature = delegate.getFeature() {
            delegate.update()
            switch feature {
            case .none:
                hideAnalysis()
            case .winrate:
                showWinRate(analysis: analysis)
            case .scoreLead:
                showScoreLead(analysis: analysis)
            case .visits:
                showVisits(analysis: analysis)
            }
        }
    }
    
    func hideAnalysis() -> Void {
        analyzerBoard?.removeAllChildren()
    }
    
    func showWinRate(analysis: GameAnalysis) -> Void {
        //print("gameAnalysis = \(gameAnalysis)")
        analyzerBoard?.removeAllChildren()
        
        for k in 0..<analysis.otherPlays.count {
            if let node = self.yellowSpot?.copy() as! SKShapeNode? {
                node.name = "yellow spot: \(k)"
                node.position = pointFor(intersection: analysis.otherPlays[k].location)
                node.lineWidth = 0
                node.fillColor = .systemYellow
                
                let font = NSFont.systemFont(ofSize: 10)
                
                let winrateNode = SKLabelNode(fontNamed: font.fontName)
                winrateNode.position = CGPoint(x: 0.0, y: 0.0)
                winrateNode.name = "winrate"
                winrateNode.text = String(format: "%0.3f", analysis.otherWinrates[k])
                winrateNode.fontSize = font.pointSize
                winrateNode.fontColor = .black
                winrateNode.verticalAlignmentMode = .center
                
                node.addChild(winrateNode)
                
                analyzerBoard?.addChild(node)
            }
        }
        
        let winrate = analysis.winrate
        if let node = self.blueSpot?.copy() as! SKShapeNode? {
            node.name = "blue spot"
            node.position = pointFor(intersection: analysis.bestNextPlay.location)
            node.lineWidth = 0
            node.fillColor = .systemBlue
            
            let font = NSFont.systemFont(ofSize: 10)
            
            let winrateNode = SKLabelNode(fontNamed: font.fontName)
            winrateNode.position = CGPoint(x: 0.0, y: 0.0)
            winrateNode.name = "winrate"
            winrateNode.text = String(format: "%0.3f", winrate)
            winrateNode.fontSize = font.pointSize
            winrateNode.fontColor = .black
            winrateNode.verticalAlignmentMode = .center
            
            node.addChild(winrateNode)
            
            analyzerBoard?.addChild(node)
        }
    }
    
    func showScoreLead(analysis: GameAnalysis) -> Void {
        //print("gameAnalysis = \(gameAnalysis)")
        analyzerBoard?.removeAllChildren()
        
        for k in 0..<analysis.otherPlays.count {
            if let node = self.yellowSpot?.copy() as! SKShapeNode? {
                node.name = "yellow spot: \(k)"
                node.position = pointFor(intersection: analysis.otherPlays[k].location)
                node.lineWidth = 0
                node.fillColor = .systemYellow
                
                let font = NSFont.systemFont(ofSize: 10)
                
                let scoreLeadNode = SKLabelNode(fontNamed: font.fontName)
                scoreLeadNode.position = CGPoint(x: 0.0, y: 0.0)
                scoreLeadNode.name = "scoreLead"
                scoreLeadNode.text = String(format: "%0.1f", analysis.otherScoreLeads[k])
                scoreLeadNode.fontSize = font.pointSize
                scoreLeadNode.fontColor = .black
                scoreLeadNode.verticalAlignmentMode = .center
                
                node.addChild(scoreLeadNode)
                
                analyzerBoard?.addChild(node)
            }
        }
        
        let scoreLead = analysis.scoreLead
        if let node = self.blueSpot?.copy() as! SKShapeNode? {
            node.name = "blue spot"
            node.position = pointFor(intersection: analysis.bestNextPlay.location)
            node.lineWidth = 0
            node.fillColor = .systemBlue
            
            let font = NSFont.systemFont(ofSize: 10)
            
            let scoreLeadNode = SKLabelNode(fontNamed: font.fontName)
            scoreLeadNode.position = CGPoint(x: 0.0, y: 0.0)
            scoreLeadNode.name = "scoreLead"
            scoreLeadNode.text = String(format: "%0.1f", scoreLead)
            scoreLeadNode.fontSize = font.pointSize
            scoreLeadNode.fontColor = .black
            scoreLeadNode.verticalAlignmentMode = .center
            
            node.addChild(scoreLeadNode)
            
            analyzerBoard?.addChild(node)
        }
    }
    
    func showVisits(analysis: GameAnalysis) -> Void {
        //print("gameAnalysis = \(gameAnalysis)")
        analyzerBoard?.removeAllChildren()
        
        for k in 0..<analysis.otherPlays.count {
            if let node = self.yellowSpot?.copy() as! SKShapeNode? {
                node.name = "yellow spot: \(k)"
                node.position = pointFor(intersection: analysis.otherPlays[k].location)
                node.lineWidth = 0
                node.fillColor = .systemYellow
                
                let font = NSFont.systemFont(ofSize: 10)
                
                let scoreLeadNode = SKLabelNode(fontNamed: font.fontName)
                scoreLeadNode.position = CGPoint(x: 0.0, y: 0.0)
                scoreLeadNode.name = "scoreLead"
                scoreLeadNode.text = String(format: "%d", analysis.otherVisits[k])
                scoreLeadNode.fontSize = font.pointSize
                scoreLeadNode.fontColor = .black
                scoreLeadNode.verticalAlignmentMode = .center
                
                node.addChild(scoreLeadNode)
                
                analyzerBoard?.addChild(node)
            }
        }
        
        let visits = analysis.visits
        if let node = self.blueSpot?.copy() as! SKShapeNode? {
            node.name = "blue spot"
            node.position = pointFor(intersection: analysis.bestNextPlay.location)
            node.lineWidth = 0
            node.fillColor = .systemBlue
            
            let font = NSFont.systemFont(ofSize: 10)
            
            let scoreLeadNode = SKLabelNode(fontNamed: font.fontName)
            scoreLeadNode.position = CGPoint(x: 0.0, y: 0.0)
            scoreLeadNode.name = "scoreLead"
            scoreLeadNode.text = String(format: "%d", visits)
            scoreLeadNode.fontSize = font.pointSize
            scoreLeadNode.fontColor = .black
            scoreLeadNode.verticalAlignmentMode = .center
            
            node.addChild(scoreLeadNode)
            
            analyzerBoard?.addChild(node)
        }
    }
    
    private func pointFor(intersection: Intersection) -> CGPoint {
        return pointFor(column: intersection.column, row: intersection.row)
    }
    
    private func pointFor(column: Int, row: Int) -> CGPoint {
        let intersectionWitdh: Float = Float(scale) * 420 / 19
        let intersectionHeight: Float = Float(scale) * 450 / 19
        
        return CGPoint(
            x: CGFloat(Float(column) * intersectionWitdh - Float(scale) * 210 + 0.5 * intersectionWitdh),
            y: CGFloat(Float(boardSize - 1 - row) * intersectionHeight - Float(scale) * 225 + 0.5 * intersectionHeight))
    }
}
