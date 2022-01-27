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
    var analyzer: Analyzer?
    
    @IBOutlet weak var featurePopUpButton: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        featurePopUpButton.removeAllItems()
        featurePopUpButton.addItems(withTitles: Feature.allCases.map { $0.rawValue })

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
    
    
    @IBAction func showFeature(_ sender: NSPopUpButton) {
        guard let titleOfSelectedItem = featurePopUpButton.titleOfSelectedItem, let feature = Feature(rawValue: titleOfSelectedItem) else {
            return
        }
        
        switch feature {
        case .none:
            scene?.clear()
        case .black:
            scene?.show(blackLocations: analyzer!.blackLocations)
        case .white:
            scene?.show(whiteLocations: analyzer!.whiteLocations)
        case .sequence:
            scene?.show(sequence: analyzer!.sequenceLocations)
        case .allowed:
            scene?.show(allowed: analyzer!.allowedLocations)
        case .chain:
            scene?.show(chains: analyzer!.chainLocations)
        case .liberty:
            scene?.show(liberties: analyzer!.libertyLocations)
        }
    }
    
    
}
