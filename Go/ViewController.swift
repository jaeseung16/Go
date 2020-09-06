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
    
    var gameAnalyzer: GameAnalyzer?
    
    var start: TimeInterval?
    var previousTime = TimeInterval()
    var blackTimer: TimeInterval?
    var whiteTimer: TimeInterval?
    
    var isBlackWillPlay = true
    var isWhiteWillPlay = false
    
    @IBOutlet weak var clockLabel: NSTextField!
    
    @IBOutlet weak var blackTimerLabel: NSTextField!
    @IBOutlet weak var whiteTimerLabel: NSTextField!
    
    @IBOutlet weak var showAnalysis: NSButton!
    
    
    @IBAction func activateAnalyzer(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.title = "Select an engine"

        openPanel.beginSheetModal(for:view.window!) { (response) in
            if response == NSApplication.ModalResponse.OK {
                print("openPanel.url! = \(openPanel.url!)")
                _ = openPanel.url!.path
                // do whatever you what with the file path
                self.gameAnalyzer = GameAnalyzer(with: openPanel.url!)
                self.gameAnalyzer?.startEngine()
            }
            openPanel.close()
        }
        
    }
    
    let dateFormatter = DateFormatter()
    
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
    
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        
        /*
        print("*****")
        gtp_finish_response()
        gtp_panic()
        print("*****")
        */
        
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
    
    func togglePlayer() {
        isBlackWillPlay = !isBlackWillPlay
        isWhiteWillPlay = !isWhiteWillPlay
    }
    
    func updateTimers(_ currentTime: TimeInterval) {
        let dt = currentTime - self.previousTime
        self.previousTime = currentTime
        
        if isBlackWillPlay {
            blackTimer = blackTimer! - dt
        }
        
        if isWhiteWillPlay {
            whiteTimer = whiteTimer! - dt
        }
        
        updateTimerLabel()
    }
    
    func updateTimerLabel() {
        let timer = isBlackWillPlay ? blackTimer! : whiteTimer!
        let timerLabel = isBlackWillPlay ? blackTimerLabel : whiteTimerLabel
        
        timerLabel?.stringValue = generateTimerString(timer)
    }
    
    func generateTimerString(_ timer :TimeInterval) -> String {
        let hours = String(format: "%02d", Int(timer / 3600.0))
        let minutes = String(format: "%02d", Int(timer.truncatingRemainder(dividingBy: 3600.0) / 60.0))
        let seconds = String(format: "%02d", Int(timer.truncatingRemainder(dividingBy: 60.0)))
        let subseconds = String(format: "%1d", Int((timer - timer.rounded(.towardZero) ) * 10.0 ))
        
        return "\(hours):\(minutes):\(seconds).\(subseconds)"
    }
    
}

extension ViewController: GameDelegate {
    func play(stone: Stone, column: Int, row: Int) -> Void {
        let play = Play(id: playNumber, row: row, column: column, stone: stone)
        
        plays.append(play)
        prohibitedPlays.insert(play)
        playNumber += 1

        print("prohibitedPlays = \(prohibitedPlays)")
        print("plays = \(plays)")
        togglePlayer()
        gameAnalyzer?.analyze(plays: plays)
    }
    
    func isPlayable(stone: Stone, column: Int, row: Int) -> Bool {
        let play = Play(id: playNumber, row: row, column: column, stone: stone)
        return !prohibitedPlays.contains(play)
    }
    
    func updateClock(_ currentTime: TimeInterval) -> Void {
        guard let start = self.start else {
            self.start = currentTime
            self.previousTime = currentTime
            self.whiteTimer = 180.0
            self.blackTimer = 180.0
            return
        }
        
        let interval = currentTime - start
        clockLabel.stringValue = generateTimerString(interval)
        
        updateTimers(currentTime)
    }
    
    func needToShowAnalysis() -> Bool {
        return showAnalysis.state == .on
    }
}
