//
//  PlayGoBots.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 6/28/26.
//

import ArgumentParser
import GoAgent
import GoBoard

@main
struct PlayGoBots: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(commandName: "play-bots",
              abstract: "Play Go against bots")
    }
    
    @Option(help: "The number of games to play")
    var games: Int

    
    static func main() {
        print("Hello, world!")
        
        let board = ZobristGoBoard(dimension: 9)
        DisplayHelper.display(board: board)
    }
    
}
