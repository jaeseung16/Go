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
        
        print("newLocation = \(newLocation)")
        print("neighborsSameStone = \(neighborsSameStone)")
        print("neighborsOppositeStone = \(neighborsOppositeStone)")
        print("liberties = \(liberties)")
        
        var newLocations = Set<Intersection>()
        newLocations.insert(newLocation)
        
        if neighborsSameStone.count == 0 && neighborsOppositeStone.count == 0 {
            let newGroup = Group(id: lastPlay.id, stone: lastPlay.stone, locations: newLocations, liberties: liberties, oppenentLocations: neighborsOppositeStone)
            groups.insert(newGroup)
        } else {
            var newLiberties = Set<Intersection>(liberties)
            var newOppoenentLocations = Set<Intersection>(neighborsOppositeStone)

            var groupsToUpdate = Set<Group>()
            var opponentGroupsToUpdate = Set<Group>()
            var groupsToRemoveFromGoBoard = Set<Group>()
            var newGroups = Set<Group>()
            
            for group in groups {
                if group.liberties.contains(newLocation) {
                    if group.stone == lastPlay.stone {
                        groupsToUpdate.insert(group)
                        print("Add to groupsToUpdate: group id = \(group.id)")
                    } else {
                        opponentGroupsToUpdate.insert(group)
                        print("Add to opponentGroupsToUpdate: group id = \(group.id)")
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
            
            print("newGroup = \(newGroup)")
            newGroups.insert(newGroup)
            
            print("opponentGroupsToUpdate.count = \(opponentGroupsToUpdate.count)")
            opponentGroupsToUpdate.forEach { group in
                print("group id = \(group.id)")
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
                print("newGroup = \(newGroup)")
                if newLiberties.isEmpty {
                    groupsToRemoveFromGoBoard.insert(newGroup)
                } else {
                    newGroups.insert(newGroup)
                }
            }
            
            opponentGroupsToUpdate.forEach { groupToRemove in
                let index = groups.firstIndex { group -> Bool in
                    return groupToRemove.id == group.id
                }
                groups.remove(at: index!)
            }
            
            groupsToUpdate.forEach { groupToRemove in
                let index = groups.firstIndex { (group) -> Bool in
                    return groupToRemove.id == group.id
                }
                groups.remove(at: index!)
            }
            
            groups.formUnion(newGroups)
            
            print("groups = \(groups)")
            
            print("groupsToRemoveFromGoBoard.count = \(groupsToRemoveFromGoBoard.count)")
            
            newGroups.removeAll()
            groupsToUpdate.removeAll()
            groupsToRemoveFromGoBoard.forEach { group in
                if group.stone != lastPlay.stone && group.liberties.count == 0 {
                    if group.locations.count == 1 {
                        ko = group.locations.first
                    }
                    for location in group.locations {
                        print("Remove location: \(location)")
                        goBoard.update(row: location.row, column: location.column, stone: nil)
                        
                        groups.forEach { aGroup in
                            if aGroup.opponentLocations.contains(location) {
                                var newOppoenentLocations = Set<Intersection>()
                                var newLiberties = Set<Intersection>()
                                
                                aGroup.opponentLocations.forEach { opponentLocation in
                                    if opponentLocation == location {
                                        newLiberties.insert(opponentLocation)
                                    } else {
                                        newOppoenentLocations.insert(opponentLocation)
                                    }
                                    
                                }
                                    
                                newLiberties.formUnion(aGroup.liberties)
                                
                                let newGroup = Group(id: aGroup.id, stone: aGroup.stone, locations: aGroup.locations, liberties: newLiberties, oppenentLocations: newOppoenentLocations)
                                
                                groupsToUpdate.insert(aGroup)
                                newGroups.insert(newGroup)
                            }
                        }
                    }
                    
                    for play in plays {
                        let isInGroup = group.locations.contains { location -> Bool in
                            return location == play.location
                        }
              
                        //print("isInGroup = \(isInGroup) vs locations.contains = \(group.locations.contains(play.location))")
                        
                        if isInGroup && play.stone != lastPlay.stone {
                            print("Removing \(play))")
                            scene?.removeStones(at: "\(play.id)")
                        }
                    }
                    
                }
            }
            
            print("groupsToUpdate.count = \(groupsToUpdate.count)")
            groupsToUpdate.forEach { groupToRemove in
                print("groupToRemove.id = \(groupToRemove.id)")
                let index = groups.firstIndex { group -> Bool in
                    return groupToRemove.id == group.id
                }
                print("index = \(index)")
                groups.remove(at: index!)
                print("groups.count = \(groups.count)")
            }
            
            groups.formUnion(newGroups)
            
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
        let newLocation = Intersection(row: row, column: column, stone: stone, forbidden: false, isEye: false)
        
        
        var canPlay = goBoard.status(row: row, column: column) == nil
        
        if canPlay && (ko != nil) && (ko == newLocation) {
            print("ko = \(ko)")
            canPlay = false
        }
        
        for group in groups {
            if group.stone == stone && group.liberties.count == 1 && group.liberties.contains(newLocation) {
                print("group = \(group)")
                canPlay = false
                break
            }
        }
        
        // Need to check ko
        // let status = goBoard.status(row: row, column: column)
        // let play = Play(id: playNumber, row: row, column: column, stone: stone)
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
