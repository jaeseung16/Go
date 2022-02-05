//
//  AIViewController.swift
//  Go
//
//  Created by Jae Seung Lee on 2/3/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import Cocoa
import SpriteKit
import Combine

class AIViewController: NSViewController {

    var game: Game?
    var goBoard: GoBoard?
    var scene: AIScene?
    let gameAnalyzer = GameAnalyzer.shared
    var numberOfPlays = 0
    
    var cancellable = Set<AnyCancellable>()
    
    @IBOutlet weak var initializingAnalyzerProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var initializingAnalyzerLabel: NSTextField!
    
    @IBOutlet weak var featurePopUpButton: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        featurePopUpButton.removeAllItems()
        featurePopUpButton.addItems(withTitles: AnalyzerFeature.allCases.map { $0.rawValue })
        
        initializingAnalyzerLabel.isHidden = true
        initializingAnalyzerProgressIndicator.isHidden = true
        
        let skView = view as! SKView
        scene = AIScene(size: skView.bounds.size, boardSize: game!.goBoard.size)
            
        // Set the scale mode to scale to fit the window
        scene!.scaleMode = .aspectFill
        scene!.sceneDelegate = self
                
        // Present the scene
        skView.presentScene(scene)
            
        skView.ignoresSiblingOrder = true
            
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        gameAnalyzer.$isReady.sink { [weak self] value in
            DispatchQueue.main.async {
                /*
                guard let viewController = self else {
                    return
                }
                 */
                self?.initializingAnalyzerLabel.isHidden = value
                self?.initializingAnalyzerProgressIndicator.isHidden = value
                
                if value {
                    self?.initializingAnalyzerProgressIndicator.stopAnimation(nil)
                    self?.analyze()
                } else {
                    self?.initializingAnalyzerProgressIndicator.startAnimation(nil)
                }
            }
        }
        .store(in: &self.cancellable)

    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if gameAnalyzer.isEngingStarted {
            analyze()
        } else {
            activateAnalyzer()
        }
    }
    
    func activateAnalyzer() -> Void {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.title = "Select an engine"

        openPanel.beginSheetModal(for: view.window!) { (response) in
            if response == NSApplication.ModalResponse.OK {
                print("openPanel.url! = \(openPanel.url!)")
                _ = openPanel.url!.path
                // do whatever you what with the file path
                self.gameAnalyzer.setEngine(with: openPanel.url!)
                self.gameAnalyzer.startEngine()
            }
            openPanel.close()
        }
    }
    
    func analyze() {
        guard let plays = game?.plays else {
            return
        }
        
        if numberOfPlays < plays.count {
            numberOfPlays = plays.count
            gameAnalyzer.analyze(plays: plays)
        }
    }
    
}

extension AIViewController: AISceneDelegate {
    func getAnalysis() -> GameAnalysis? {
        return gameAnalyzer.getResult()
    }
    
    func getFeature() -> AnalyzerFeature? {
        return AnalyzerFeature(rawValue: featurePopUpButton.titleOfSelectedItem ?? "none")
    }
    
    func update() -> Void {
        analyze()
    }
}
