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
import SmartGameFormat_Swift

class ViewController: NSViewController {
    var playNumber: Int = 0
    var plays = [Play]()
    var scene: GameScene?
    var groups = Set<Group>()
    
    var game: Game?
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
    
    var features = [Intersections]()
    
    @IBOutlet weak var clockLabel: NSTextField!
    
    @IBOutlet weak var blackTimerLabel: NSTextField!
    @IBOutlet weak var whiteTimerLabel: NSTextField!
    
    @IBOutlet weak var showAnalysis: NSButton!
    
    @IBOutlet weak var blackWinningProbabilityIndicator: NSLevelIndicator!
    
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let boardSize = 19
        
        goBoard = GoBoard(size: boardSize)
        
        game = Game(goBoard: goBoard!)
        
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
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let analyzerViewController = segue.destinationController as? FeaturesViewController {
            analyzerViewController.game = game
            analyzerViewController.analyzer = Analyzer(game: game!, plays: plays, goBoard: goBoard!, groups: groups, removedStones: removedStones)
        } else if let aiViewController = segue.destinationController as? AIViewController {
            aiViewController.game = game
        }
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm"
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "Untitled_\(dateFormatter.string(from: Date())).sgf"
        savePanel.canCreateDirectories = false
        savePanel.title = "Save a SGF file"
        
        savePanel.beginSheetModal(for: view.window!) { response in
            if response == NSApplication.ModalResponse.OK {
                let sgfHelper = SGFHelper()
                sgfHelper.load(from: self.plays)
                print("\(sgfHelper.gameTrees)")
                sgfHelper.save(to: savePanel.url!)
            }
        }
    }
    
    @IBAction func loadGame(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.title = "Select a SGF file"

        openPanel.beginSheetModal(for: view.window!) { response in
            if response == NSApplication.ModalResponse.OK {
                let sgfHelper = SGFHelper()
                sgfHelper.load(from: openPanel.url!)
                
                if sgfHelper.succeeded {
                    let plays = sgfHelper.getPlays()
                    
                    self.sgfGameTree = sgfHelper.gameTrees[0]
                    
                    DispatchQueue.main.async {
                        plays?.forEach({ play in
                            self.scene?.add(stone: play.stone, at: play.location, count: play.id)
                        })
                    }
                }
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
    func play(stone: Stone, at intersection: Intersection) -> Void {
        guard let game = game else {
            return
        }

        let play = Play(id: playNumber, row: intersection.row, column: intersection.column, stone: stone)
        plays.append(play)
        playNumber += 1

        ko = nil
        
        game.append(play: play)
        
        updateGroups()
        
        togglePlayer()
        gameAnalyzer?.analyze(plays: plays)
    }
    
    func isPlayable(stone: Stone, at intersection: Intersection) -> Bool {
        let nextPlay = Play(id: playNumber, row: intersection.row, column: intersection.column, stone: stone)
        
        var canPlay = goBoard!.status(row: intersection.row, column: intersection.column) == nil
        
        if canPlay {
            let groupAnalyzer = GroupAnalyzer(play: nextPlay, goBoard: goBoard!, groups: groups, lastPlay: plays.last, removedStones: removedStones)
            if !groupAnalyzer.allNeighborsAreLiberties {
                canPlay = groupAnalyzer.isPlayable
            }
        }
        return canPlay
    }
    
    func playablePositions(stone: Stone) -> [Intersection] {
        print("playablePositions: \(stone)")
        
        var positions = [Intersection]()
        for row in 0..<goBoard!.size {
            for column in 0..<goBoard!.size {
                let nextPlay = Play(id: playNumber, row: row, column: column, stone: stone)
                
                var canPlay = goBoard!.status(row: row, column: column) == nil
                
                if canPlay {
                    let groupAnalyzer = GroupAnalyzer(play: nextPlay, goBoard: goBoard!, groups: groups, lastPlay: plays.last, removedStones: removedStones)
                    if !groupAnalyzer.allNeighborsAreLiberties {
                        canPlay = groupAnalyzer.isPlayable
                    }
                }
                
                if canPlay {
                    positions.append(Intersection(row: row, column: column))
                }
            }
        }
        
        return positions
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
