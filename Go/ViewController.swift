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
        
        print("lastPlay = \(lastPlay)")
        
        goBoard.update(row: lastPlay.location.row, column: lastPlay.location.column, stone: lastPlay.stone)
        
        let newLocation = Intersection(row: lastPlay.location.row, column: lastPlay.location.column, stone: lastPlay.stone, forbidden: false, isEye: false)
        let neighborsSameStone = neighbors(of: lastPlay, with: lastPlay.stone)
        let neighborsOppositeStone = neighbors(of: lastPlay, with: lastPlay.stone == .Black ? .White : .Black)
        let liberties = neighbors(of: lastPlay, with: nil)
        
        //print("liberties = \(liberties)")
        
        var newLocations = Set<Intersection>()
        newLocations.insert(newLocation)
        
        if neighborsSameStone.count == 0 && neighborsOppositeStone.count == 0 {
            let newGroup = Group(id: lastPlay.id, stone: lastPlay.stone, locations: newLocations, liberties: liberties, oppenentLocations: neighborsOppositeStone)
            groups.insert(newGroup)
        } else {
            var newLiberties = Set<Intersection>(liberties)
            var newOppoenentLocations = Set<Intersection>()

            var groupsToUpdate = Set<Group>()
            var opponentGroupsToUpdate = Set<Group>()
            var groupsToRemove = Set<Int>()
            var newGroups = Set<Group>()
            
            for group in groups {
                if group.liberties.contains(newLocation) {
                    if group.stone == lastPlay.stone {
                        groupsToUpdate.insert(group)
                    } else {
                        opponentGroupsToUpdate.insert(group)
                    }
                }
            }
            
            groupsToUpdate.forEach { (group) in
                newLocations.formUnion(group.locations)
                newOppoenentLocations.formUnion(group.opponentLocations)
                group.liberties.forEach { liberty in
                    if (liberty != newLocation) {
                        newLiberties.insert(liberty)
                    }
                }
            }
            
            let newGroup = Group(id: lastPlay.id, stone: lastPlay.stone, locations: newLocations, liberties: newLiberties, oppenentLocations: newOppoenentLocations)
            newGroups.insert(newGroup)
            
            opponentGroupsToUpdate.forEach { group in
                newLiberties.removeAll()
                newOppoenentLocations.removeAll()
                
                group.liberties.forEach { liberty in
                    if (liberty != newLocation) {
                        newLiberties.insert(liberty)
                    }
                }
                
                newOppoenentLocations.insert(newLocation)
                newOppoenentLocations.formUnion(group.opponentLocations)
                
                let newGroup = Group(id: group.id, stone: group.stone, locations: group.locations, liberties: newLiberties, oppenentLocations: newOppoenentLocations)
                newGroups.insert(newGroup)
            }
            
            groupsToUpdate.forEach { groupToRemove in
                let index = groups.firstIndex { (group) -> Bool in
                    return groupToRemove.id == group.id
                }
                groups.remove(at: index!)
            }
            
            opponentGroupsToUpdate.forEach { groupToRemove in
                let index = groups.firstIndex { (group) -> Bool in
                    return groupToRemove.id == group.id
                }
                groups.remove(at: index!)
            }
            
            groups.formUnion(newGroups)
        }
        
        print("groups.count = \(groups.count)")
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
