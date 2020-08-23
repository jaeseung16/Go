//
//  ViewController.swift
//  Go
//
//  Created by Jae Seung Lee on 8/4/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {
    var playNumber: Int = 0
    var plays = [Play]()
    var prohibitedPlays = Set<Play>()
    var scene: GameScene?

    override func viewDidLoad() {
        super.viewDidLoad()

        let skView = view as! SKView
            
        scene = GameScene(size: skView.bounds.size)
            
        // Set the scale mode to scale to fit the window
        scene!.scaleMode = .aspectFill
        scene!.gameDelegate = self
                
        // Present the scene
        skView.presentScene(scene)
            
        skView.ignoresSiblingOrder = true
            
        skView.showsFPS = true
        skView.showsNodeCount = true
    
        
    }
    
    @IBAction func playBackward(_ sender: NSButton) {
        if scene!.hide(number: playNumber-1) {
            playNumber -= 1
        }
        print("\(playNumber)")
    }
    
    @IBAction func playForward(_ sender: NSButton) {
        if scene!.show(number: playNumber) {
            playNumber += 1
        }
        print("\(playNumber)")
    }
    
    @IBAction func showSequence(_ sender: NSButton) {
        scene?.showSequence()
    }
}

extension ViewController: GameDelegate {
    func play(stone: Stone, column: Int, row: Int) -> Void {
        let play = Play(id: playNumber, row: row, column: column, stone: stone)
        
        plays.append(play)
        prohibitedPlays.insert(play)
        playNumber += 1

        print("prohibitedPlays = \(prohibitedPlays)")
    }
    
    func isPlayable(stone: Stone, column: Int, row: Int) -> Bool {
        let play = Play(id: playNumber, row: row, column: column, stone: stone)
        return !prohibitedPlays.contains(play)
    }
}
