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
    var scene: GameScene?
    var groups = Set<Group>()
    
    var goBoard = GoBoard()
    
    var gameAnalyzer: GameAnalyzer?
    
    var start: TimeInterval?
    var previousTime = TimeInterval()
    var blackTimer: TimeInterval?
    var whiteTimer: TimeInterval?
    
    var isBlackWillPlay = true
    var isWhiteWillPlay = false
    
    var ko: Intersection?
    var removedStones = Set<Intersection>()
    
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
    
    func neighbors(of play: Play, with status: Stone?) -> Set<Intersection> {
        var neighbors = Set<Intersection>()
        
        for neighbor in Neighbor.allCases {
            switch neighbor {
            case .up:
                if play.location.row > 0 && status == goBoard.status(row: play.location.row - 1, column: play.location.column) {
                    neighbors.insert(Intersection(row: play.location.row - 1, column: play.location.column, stone: status, forbidden: false, isEye: false))
                }
            case .down:
                if play.location.row < goBoard.size - 1 && status == goBoard.status(row: play.location.row + 1, column: play.location.column) {
                    neighbors.insert(Intersection(row: play.location.row + 1, column: play.location.column, stone: status, forbidden: false, isEye: false))
                }
            case .left:
                if play.location.column > 0 && status == goBoard.status(row: play.location.row, column: play.location.column - 1) {
                    neighbors.insert(Intersection(row: play.location.row, column: play.location.column - 1, stone: status, forbidden: false, isEye: false))
                }
            case .right:
                if play.location.column < goBoard.size - 1  && status == goBoard.status(row: play.location.row, column: play.location.column + 1) {
                    neighbors.insert(Intersection(row: play.location.row, column: play.location.column + 1, stone: status, forbidden: false, isEye: false))
                }
            }
        }
        
        return neighbors
    }
    
    
    func updateGroups() -> Void {
        guard let lastPlay = plays.last else {
            return
        }
        
        removedStones.removeAll()
        
        print("lastPlay = \(lastPlay)")
        //print("goBoard.status = \(goBoard.status(row: 15, column: 16))")
        let groupAnalyzer = GroupAnalyzer(play: lastPlay, goBoard: goBoard, groups: groups)
        goBoard.update(row: lastPlay.location.row, column: lastPlay.location.column, stone: lastPlay.stone)
        
        let newLocation = Intersection(row: lastPlay.location.row, column: lastPlay.location.column, stone: lastPlay.stone, forbidden: false, isEye: false)
        let neighborsSameStone = groupAnalyzer.neighborsSameStone
        let neighborsOppositeStone = groupAnalyzer.neighborsOppositeStone
        let liberties = groupAnalyzer.liberties
        
        print("newLocation = \(newLocation)")
        print("neighborsSameStone = \(neighborsSameStone)")
        print("neighborsOppositeStone = \(neighborsOppositeStone)")
        print("liberties = \(liberties)")
        
        if groupAnalyzer.allNeighborsAreLiberties {
            let newLocations = Set<Intersection>(arrayLiteral: newLocation)
            let newGroup = Group(id: lastPlay.id,
                                 stone: lastPlay.stone,
                                 locations: newLocations,
                                 liberties: groupAnalyzer.liberties,
                                 oppenentLocations: groupAnalyzer.neighborsOppositeStone)
            groups.insert(newGroup)
        } else {
            groupAnalyzer.generateIntermidiateGroupsGroups()
            
            print("groupsToRemoveFromGoBoard.count = \(groupAnalyzer.groupsToRemove.count)")
            groupAnalyzer.processGroupsToRemove()
            
            groupAnalyzer.locationsToRemove!.forEach { location in
                print("Remove location: \(location)")
                goBoard.update(row: location.row, column: location.column, stone: nil)
                removedStones.insert(location)
                
                for play in plays {
                    if location == play.location && play.stone != lastPlay.stone {
                        print("Removing \(play))")
                        scene?.removeStones(at: "\(play.id)")
                    }
                }
            }
            
            groups = groupAnalyzer.nextGroups
        }
        
        print("groups = \(groups)")
    }
    
}

extension ViewController: GameDelegate {
    func play(stone: Stone, column: Int, row: Int) -> Void {
        let play = Play(id: playNumber, row: row, column: column, stone: stone)
        
        plays.append(play)
        playNumber += 1

        ko = nil
        updateGroups()
        
        togglePlayer()
        gameAnalyzer?.analyze(plays: plays)
    }
    
    func isPlayable(stone: Stone, column: Int, row: Int) -> Bool {
        print("isPlayable: \(stone) @ row = \(row), column = \(column)")
        let nextPlay = Play(id: playNumber, row: row, column: column, stone: stone)
        
        let groupAnalyzer = GroupAnalyzer(play: nextPlay, goBoard: goBoard, groups: groups)
        var canPlay = goBoard.status(row: row, column: column) == nil
        
        if !groupAnalyzer.allNeighborsAreLiberties {
            groupAnalyzer.generateIntermidiateGroupsGroups()
            groupAnalyzer.processGroupsToRemove()
            
            // check suicide, seems working
            groupAnalyzer.nextGroups.forEach { group in
                if group.liberties.count == 0 {
                    canPlay = false
                    print("possible suicide")  // not perfect?
                } else if group.liberties.count == 1 {
                    print("removedStones = \(removedStones), plays.last.location = \(plays.last!.location)")
                    if group.liberties.first == plays.last!.location && removedStones.contains(nextPlay.location) {
                        canPlay = false
                        print("possible ko")
                    }
                }
            }
        }
        
        return canPlay
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
