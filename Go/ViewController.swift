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
    
    var goBoard: GoBoard?
    
    var gameAnalyzer: GameAnalyzer?
    
    var start: TimeInterval?
    var previousTime = TimeInterval()
    var blackTimer: TimeInterval?
    var whiteTimer: TimeInterval?
    
    var isBlackWillPlay = true
    var isWhiteWillPlay = false
    
    var ko: Intersection?
    var removedStones = Set<Intersection>()
    
    var sgfGameTree: SGFGameTree?
    
    @IBOutlet weak var clockLabel: NSTextField!
    
    @IBOutlet weak var blackTimerLabel: NSTextField!
    @IBOutlet weak var whiteTimerLabel: NSTextField!
    
    @IBOutlet weak var showAnalysis: NSButton!
    
    @IBOutlet weak var blackWinningProbabilityIndicator: NSLevelIndicator!
    
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

        let boardSize = 19
        
        goBoard = GoBoard(size: boardSize)
        
        let skView = view as! SKView
            
        scene = GameScene(size: skView.bounds.size, boardSize: boardSize)
            
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
    
    
    @IBAction func showTeriitories(_ sender: NSButton) {
        let score = Score()
        score.board = goBoard!
        
        let result = score.evaluate()
        print("\(score.board!)")
        
        scene?.showTerritories(board: score.board!)
    }
    
    @IBAction func saveGame(_ sender: NSButton) {
        var count = 0
        for node in self.sgfGameTree!.nodelist! {
            //sleep(1)
            //print("\(count): \(node)")
            
            if node.data.contains(where: { (key, _) -> Bool in
                return key == "W"
            }) {
                print("\(count): \(node.data["W"])")
                let sgfCoordinate = node.data["W"]!.values![0]
                
                let sgfRow = SGFCoordinate(rawValue: String(sgfCoordinate.last!))!
                let sgfcolumn = SGFCoordinate(rawValue: String(sgfCoordinate.first!))!
                print("\(sgfRow.toNumber()), \(sgfcolumn.toNumber())")
                
                self.play(stone: .White, column: sgfcolumn.toNumber(), row: sgfRow.toNumber())
                scene?.addStone(.White, count: count, column: sgfcolumn.toNumber(), row: sgfRow.toNumber())
            } else if node.data.contains(where: { (key, _) -> Bool in
                return key == "B"
            }) {
                print("\(count): \(node.data["B"])")
                let sgfCoordinate = node.data["B"]!.values![0]
                let sgfRow = SGFCoordinate(rawValue: String(sgfCoordinate.last!))!
                let sgfcolumn = SGFCoordinate(rawValue: String(sgfCoordinate.first!))!
                print("\(sgfRow.toNumber()), \(sgfcolumn.toNumber())")
                
                self.play(stone: .Black, column: sgfcolumn.toNumber(), row: sgfRow.toNumber())
                scene?.addStone(.Black, count: count, column: sgfcolumn.toNumber(), row: sgfRow.toNumber())
            } else {
                continue
            }
            
            count += 1
        }
    }
    
    @IBAction func loadGame(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.title = "Select a SGF file"

        openPanel.beginSheetModal(for:view.window!) { (response) in
            if response == NSApplication.ModalResponse.OK {
                _ = openPanel.url!.path
                // do whatever you what with the file path
                var inputString = try! String(contentsOf: openPanel.url!)
                inputString.removeAll(where: { $0 == "\n" })
                
                let parser = SGFParser(inputString)
            
                do {
                    try parser.parse()
                } catch {
                    // TODO: Show something to the user
                    print("Failed parsing inputString: \(error)")
                }
                
                //print("parser.gameTrees = \(parser.gameTrees)")
                
                self.sgfGameTree = parser.gameTrees[0]
            }
            openPanel.close()
        }
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

    func updateGroups() -> Void {
        guard let lastPlay = plays.last else {
            return
        }
        
        removedStones.removeAll()
        
        print("lastPlay = \(lastPlay)")
        //print("goBoard.status = \(goBoard.status(row: 15, column: 16))")
        let groupAnalyzer = GroupAnalyzer(play: lastPlay, goBoard: goBoard!, groups: groups, lastPlay: plays.last, removedStones: removedStones)
        goBoard!.update(row: lastPlay.location.row, column: lastPlay.location.column, stone: lastPlay.stone)
        
        
        let newLocation = Intersection(row: lastPlay.location.row, column: lastPlay.location.column, stone: lastPlay.stone, forbidden: false, isEye: false)
        /*
        print("newLocation = \(newLocation)")
        print("neighborsSameStone = \(groupAnalyzer.neighborsSameStone)")
        print("neighborsOppositeStone = \(groupAnalyzer.neighborsOppositeStone)")
        print("liberties = \(groupAnalyzer.liberties)")
        */
        
        if groupAnalyzer.allNeighborsAreLiberties {
            let newLocations = Set<Intersection>(arrayLiteral: newLocation)
            let newGroup = Group(id: lastPlay.id,
                                 stone: lastPlay.stone,
                                 locations: newLocations,
                                 liberties: groupAnalyzer.liberties,
                                 oppenentLocations: groupAnalyzer.neighborsOppositeStone)
            groups.insert(newGroup)
        } else {
            //print("groupsToRemoveFromGoBoard.count = \(groupAnalyzer.groupsToRemove.count)")
            
            groupAnalyzer.locationsToRemove!.forEach { location in
                print("Remove location: \(location)")
                goBoard!.update(row: location.row, column: location.column, stone: nil)
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
        
        //print("groups = \(groups)")
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
        
        var canPlay = goBoard!.status(row: row, column: column) == nil
        
        if canPlay {
            let groupAnalyzer = GroupAnalyzer(play: nextPlay, goBoard: goBoard!, groups: groups, lastPlay: plays.last, removedStones: removedStones)
            if !groupAnalyzer.allNeighborsAreLiberties {
                canPlay = groupAnalyzer.isPlayable
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
        if let gameAnalysis = gameAnalyzer?.getResult() {
            blackWinningProbabilityIndicator.doubleValue = 100.0 * gameAnalysis.winrate
        }
        
        return gameAnalyzer?.getResult()
    }
}
