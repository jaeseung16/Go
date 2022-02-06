//
//  AnalyzerViewController.swift
//  Go
//
//  Created by Jae Seung Lee on 1/24/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import Cocoa
import SpriteKit

class FeaturesViewController: NSViewController {

    var game: Game?
    var goBoard: GoBoard?
    var scene: FeaturesScene?
    var analyzer: Analyzer?
    var numberOfPlays = 0
    
    var delegate: FeaturesViewControllerDelegate?
    
    @IBOutlet weak var featurePopUpButton: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        featurePopUpButton.removeAllItems()
        featurePopUpButton.addItems(withTitles: Feature.allCases.map { $0.rawValue })
        
        let skView = view as! SKView
        scene = FeaturesScene(size: skView.bounds.size, boardSize: game!.goBoard.size)
        scene!.sceneDelegate = self
            
        // Set the scale mode to scale to fit the window
        scene!.scaleMode = .aspectFill
                
        // Present the scene
        skView.presentScene(scene)
            
        skView.ignoresSiblingOrder = true
            
        skView.showsFPS = true
        skView.showsNodeCount = true
    
    }
    
    @IBAction func showFeature(_ sender: NSPopUpButton) {
        showFeature()
    }
    
    private func showFeature() -> Void {
        guard let titleOfSelectedItem = featurePopUpButton.titleOfSelectedItem, let feature = Feature(rawValue: titleOfSelectedItem), let analyzer = analyzer else {
            return
        }
        
        switch feature {
        case .none:
            scene?.clear()
        case .black:
            scene?.show(blackLocations: analyzer.blackLocations)
        case .white:
            scene?.show(whiteLocations: analyzer.whiteLocations)
        case .sequence:
            scene?.show(sequence: analyzer.sequenceLocations)
        case .allowed:
            scene?.show(allowed: analyzer.allowedLocations)
        case .removed:
            scene?.show(removed: analyzer.removedLocations)
        case .chainBlack:
            scene?.show(chains: analyzer.chainLocations(for: .Black), for: .Black)
        case .chainWhite:
            scene?.show(chains: analyzer.chainLocations(for: .White), for: .White)
        case .libertyBlack:
            scene?.show(liberties: analyzer.libertyLocations(for: .Black), for: .Black)
        case .libertyWhite:
            scene?.show(liberties: analyzer.libertyLocations(for: .White), for: .White)
        }
    }
    
}

extension FeaturesViewController: FeaturesSceneDelegate {
    func update() -> Void {
        guard let plays = game?.plays, let delegate = delegate else {
            return
        }
        
        if numberOfPlays < plays.count {
            numberOfPlays = plays.count
            analyzer = delegate.getAnalyzer()
            showFeature()
        }
    }
}
