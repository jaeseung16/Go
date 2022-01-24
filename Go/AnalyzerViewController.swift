//
//  AnalyzerViewController.swift
//  Go
//
//  Created by Jae Seung Lee on 1/24/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import Cocoa
import SpriteKit

class AnalyzerViewController: NSViewController {

    var goBoard: GoBoard?
    var scene: AnalyzerScene?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        let boardSize = 19
        
        goBoard = GoBoard(size: boardSize)
        
        let skView = view as! SKView
            
        scene = AnalyzerScene(size: skView.bounds.size, boardSize: boardSize)
            
        // Set the scale mode to scale to fit the window
        scene!.scaleMode = .aspectFill
                
        // Present the scene
        skView.presentScene(scene)
            
        skView.ignoresSiblingOrder = true
            
        skView.showsFPS = true
        skView.showsNodeCount = true
    
    }
    
    
}
