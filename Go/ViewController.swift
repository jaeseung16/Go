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
    var groups = Set<Group>()
    
    let goBoard = GoBoard()
    
    var gameAnalyzer: GameAnalyzer?
    
    var start: TimeInterval?
    var previousTime = TimeInterval()
    var blackTimer: TimeInterval?
    var whiteTimer: TimeInterval?
    
    var isBlackWillPlay = true
    var isWhiteWillPlay = false
    
    var ko: Intersection?
    
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
    
    @IBAction func showGroups(_ sender: NSButton) {
        scene?.showGroups(groups)
    }
    
    @IBAction func showLiberties(_ sender: Any) {
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
    
    func neighbors(of play: Play, with status: Stone?) -> [Intersection] {
        var neighbors = [Intersection]()
        
        for neighbor in Neighbor.allCases {
            switch neighbor {
            case .up:
                if play.row > 0 && status == goBoard.status(row: play.row - 1, column: play.column) {
                    neighbors.append(Intersection(row: play.row - 1, column: play.column, stone: status, forbidden: false, isEye: false))
                }
            case .down:
                if play.row < goBoard.size - 1 && status == goBoard.status(row: play.row + 1, column: play.column) {
                    neighbors.append(Intersection(row: play.row + 1, column: play.column, stone: status, forbidden: false, isEye: false))
                }
            case .left:
                if play.column > 0 && status == goBoard.status(row: play.row, column: play.column - 1) {
                    neighbors.append(Intersection(row: play.row, column: play.column - 1, stone: status, forbidden: false, isEye: false))
                }
            case .right:
                if play.column < goBoard.size - 1  && status == goBoard.status(row: play.row, column: play.column + 1) {
                    neighbors.append(Intersection(row: play.row, column: play.column + 1, stone: status, forbidden: false, isEye: false))
                }
            }
        }
        
        return neighbors
    }
    
    
    func updateGroups() -> Void {
        guard let lastPlay = plays.last else {
            return
        }
        
        print("lastPlay = \(lastPlay)")
        
        goBoard.update(row: lastPlay.row, column: lastPlay.column, stone: lastPlay.stone)
        
        let newLocation = Intersection(row: lastPlay.row, column: lastPlay.column, stone: lastPlay.stone, forbidden: false, isEye: false)
        let neighborsSameStone = neighbors(of: lastPlay, with: lastPlay.stone)
        let neighborsOppositeStone = neighbors(of: lastPlay, with: lastPlay.stone == .Black ? .White : .Black)
        let liberties = neighbors(of: lastPlay, with: nil)
        
        print("liberties = \(liberties)")
        
        if neighborsSameStone.count == 0 {
            let location = Intersection(row: lastPlay.row, column: lastPlay.column, stone: lastPlay.stone, forbidden: false, isEye: false)
            let newGroup = Group(id: lastPlay.id, head: lastPlay, locations: Set<Intersection>(arrayLiteral: location), liberties: Set<Intersection>())
            groups.insert(newGroup)
        } else if neighborsSameStone.count > 0 {
            var newLocations = Set<Intersection>()
            newLocations.insert(newLocation)
            
            var groupsToRemove = Set<Group>()
            for group in groups {
                for location in group.locations {
                    if neighborsSameStone.contains(location) {
                        newLocations.formUnion(group.locations)
                        groupsToRemove.insert(group)
                    }
                }
            }
            
            let newGroup = Group(id: lastPlay.id, head: lastPlay, locations: newLocations, liberties: Set<Intersection>())
            groups.insert(newGroup)
            groupsToRemove.forEach { groups.remove($0) }
        }
        
        /*
        var neighborStatus: [Neighbor: Stone?] = [:]
        
        neighborStatus[.up] = lastPlay.row > 0 ? goBoard.status(row: lastPlay.row - 1, column: lastPlay.column) : nil
        neighborStatus[.down] = lastPlay.row < goBoard.size - 1 ? goBoard.status(row: lastPlay.row + 1, column: lastPlay.column) : nil
        neighborStatus[.left] = lastPlay.column > 0 ? goBoard.status(row: lastPlay.row, column: lastPlay.column - 1) : nil
        neighborStatus[.right] = lastPlay.column < goBoard.size - 1 ? goBoard.status(row: lastPlay.row, column: lastPlay.column + 1) : nil
        
        
        
        if neighborStatus.values.contains(lastPlay.stone) {
            print("neighborStatus = \(neighborStatus)")
            
            var neighbors = [Intersection]()
            for (neighbor, stone) in neighborStatus {
                if stone == lastPlay.stone {
                    switch neighbor {
                    case .up:
                        neighbors.append(Intersection(row: lastPlay.row - 1, column: lastPlay.column, stone: lastPlay.stone, forbidden: false, isEye: false))
                    case .down:
                        neighbors.append(Intersection(row: lastPlay.row + 1, column: lastPlay.column, stone: lastPlay.stone, forbidden: false, isEye: false))
                    case .left:
                        neighbors.append(Intersection(row: lastPlay.row, column: lastPlay.column - 1, stone: lastPlay.stone, forbidden: false, isEye: false))
                    case .right:
                        neighbors.append(Intersection(row: lastPlay.row, column: lastPlay.column + 1, stone: lastPlay.stone, forbidden: false, isEye: false))
                    }
                }
            }
            
            for index in 0..<groups.count {
                let group = groups[index]
                for location in group.locations {
                    if neighbors.contains(location) {
                        var newLocations = [Intersection]()
                        newLocations.append(contentsOf: group.locations)
                        
                        let newLocation = Intersection(row: lastPlay.row, column: lastPlay.column, stone: lastPlay.stone, forbidden: false, isEye: false)
                        newLocations.append(newLocation)
                        
                        group.locations = newLocations
                        // TODO: Merging groups
                    }
                }
            }
        }
        */
        //print("groups = \(groups)")
    }
    
}

extension ViewController: GameDelegate {
    func play(stone: Stone, column: Int, row: Int) -> Void {
        let play = Play(id: playNumber, row: row, column: column, stone: stone)
        
        plays.append(play)
        prohibitedPlays.insert(play)
        playNumber += 1

        updateGroups()
        
        //print("prohibitedPlays = \(prohibitedPlays)")
        //print("plays = \(plays)")
        togglePlayer()
        gameAnalyzer?.analyze(plays: plays)
    }
    
    func isPlayable(stone: Stone, column: Int, row: Int) -> Bool {
        // Need to check ko
        // let status = goBoard.status(row: row, column: column)
        // let play = Play(id: playNumber, row: row, column: column, stone: stone)
        return goBoard.status(row: row, column: column) == nil
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
    
    func getAnalysis() -> GameAnalysis? {
        return gameAnalyzer?.getResult()
    }
}
