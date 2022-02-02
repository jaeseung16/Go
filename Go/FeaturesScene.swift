//
//  AnalyzerScene.swift
//  Go
//
//  Created by Jae Seung Lee on 1/24/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import SpriteKit

class FeaturesScene: SKScene {
    
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
    
    func clear() -> Void {
        analyzerBoard?.removeAllChildren()
    }
    
    func show(blackLocations: BlackLocations) -> Void {
        print("show blacks")
        analyzerBoard?.removeAllChildren()
        
        let locations = blackLocations.locations
        
        for index in 0..<locations.count {
            let playNumber = 2 * index + 1
            let node = makeNode(at: locations[index], stone: .Black, name: "black \(playNumber)")
            node.addChild(makeLabel(stone: .Black, index: playNumber))
            analyzerBoard?.addChild(node)
        }
    }
    
    func show(whiteLocations: WhiteLocations) -> Void {
        print("show whites")
        analyzerBoard?.removeAllChildren()
        
        let locations = whiteLocations.locations
        
        for index in 0..<locations.count {
            let playNumber = 2 * (index + 1)
            let node = makeNode(at: locations[index], stone: .White, name: "white \(2 * index + 1)")
            node.addChild(makeLabel(stone: .White, index: playNumber))
            analyzerBoard?.addChild(node)
        }
    }
    
    func show(sequence: SequenceLocations) -> Void {
        print("show sequence")
        analyzerBoard?.removeAllChildren()
        
        let locations = sequence.locations
        
        for index in 0..<locations.count {
            let stone: Stone = index % 2 == 0 ? .Black : .White
            let name = index % 2 == 0 ? "black \(index)" : "white \(index)"
            let node = makeNode(at: locations[index], stone: stone, name: name)
            node.addChild(makeLabel(stone: stone, index: index))
            analyzerBoard?.addChild(node)
        }
    }
    
    func show(allowed: AllowedLocations) -> Void {
        print("show allowed locaations")
        analyzerBoard?.removeAllChildren()
        
        let locations = allowed.locations
        let stone: Stone = allowed.playNumber % 2 == 0 ? .Black : .White
        
        for index in 0..<locations.count {
            let name = stone == .Black ? "black \(index)" : "white \(index)"
            let node = makeNode(at: locations[index], stone: stone, name: name)
            analyzerBoard?.addChild(node)
        }
    }
    
    func show(chains: GroupLocations, for stone: Stone) -> Void {
        print("show chains for \(stone)")
        analyzerBoard?.removeAllChildren()
        
        let groups = chains.groups
        for index in 0..<groups.count {
            let stone = groups[index].stone
            let name = stone == .Black ? "black \(index)" : "white \(index)"
            
            groups[index].locations.forEach {
                let node = makeNode(at: $0, stone: stone, name: name)
                node.addChild(makeLabel(stone: stone, index: index))
                analyzerBoard?.addChild(node)
            }
        }
    }
    
    func show(liberties: LibertyLocations, for stone: Stone) -> Void {
        print("show liberties for \(stone)")
        analyzerBoard?.removeAllChildren()
        
        let locations = liberties.locations
        for index in 0..<locations.count {
            let name = stone == .Black ? "black \(index)" : "white \(index)"
            let node = makeNode(at: locations[index], stone: stone, name: name)
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
    
    private func makeNode(at intersection: Intersection, stone: Stone, name: String) -> SKShapeNode {
        var node: SKShapeNode
        
        switch stone {
        case .Black:
            node = self.blackStone!.copy() as! SKShapeNode
            node.fillTexture = blackStoneTexture
            node.fillColor = .black
        case .White:
            node = self.whiteStone!.copy() as! SKShapeNode
            node.fillTexture = whiteStoneTexture
            node.fillColor = .white
        }
        
        node.name = name
        node.position = pointFor(intersection: intersection)
        node.lineWidth = 0
        return node
    }
    
    private func makeLabel(stone: Stone, index: Int) -> SKLabelNode {
        let font = NSFont.systemFont(ofSize: (index > 99 ? 12 : 16))
        let sequence = SKLabelNode(fontNamed: font.fontName)
        sequence.name = "sequence \(index)"
        sequence.text = "\(index)"
        sequence.fontSize = font.pointSize
        sequence.verticalAlignmentMode = .center
        sequence.position = CGPoint(x: 0.0, y: 0.0)
        
        switch stone {
        case .Black:
            sequence.fontColor = .white
        case .White:
            sequence.fontColor = .black
        }
        
        return sequence
    }
}
