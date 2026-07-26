//
//  PlayGoBots.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 6/28/26.
//

import ArgumentParser
import Foundation
import GoAgent
import GoBoard
import GoBotsSupport
import Logging

@main
struct PlayGoBots: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(commandName: "play-bots",
              abstract: "Play Go against bots")
    }
    
    @Option(help: "The number of games to play")
    var games: Int

    
    static func main() async throws {
        // Route all GoAgent/GoBoard logs to a dedicated file so the terminal
        // display stays clean.
        let logURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("play-go-bots.log")
        LoggingSystem.bootstrap { label in
            do {
                var handler = try FileLogHandler(label: label, fileURL: logURL)
                handler.logLevel = .info
                return handler
            } catch {
                // Fall back to stderr if the log file can't be opened.
                var handler = StreamLogHandler.standardError(label: label)
                handler.logLevel = .error
                return handler
            }
        }

        print("Logging to \(logURL.path)")
        print("Hello, world!")
        
        let board = ZobristGoBoard(dimension: 9)
        
        let whitePlayer = NaiveAgent(stone: .white)
        let blackPlayer = NaiveAgent(stone: .black)
        
        let players: [Player: GoAgent] = [.white: whitePlayer, .black: blackPlayer]
        
        var game = GameState(board: board, nextPlayer: .black)
        
        while !game.isOver() {
            print("\u{001B}[2J")
            DisplayHelper.display(board: game.board)
            
            let move = players[game.nextPlayer]!.select(from: game)
            DisplayHelper.display(move: move, player: game.nextPlayer)
            
            game = game.apply(move: move)
            
            try await Task.sleep(for: .seconds(1))
        }
        
        DisplayHelper.display(board: game.board)
    }
    
}
