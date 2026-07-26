//
//  SelfPlay.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 7/26/26.
//

import ArgumentParser
import Foundation
import GoAgent
import GoBoard
import GoBotsSupport
import Logging
import MLX
import MLXNN
import MLXOptimizers

@main
struct SelfPlay: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(commandName: "self-play",
              abstract: "Make a bot play Go against itself")
    }

    @Option(help: "The board size")
    var boardSize: Int = 19
    
    @Option(help: "The number of games to play")
    var numGames: Int = 1
    
    @Option(help: "The name of learning agent")
    var learningAgent: String = "policy"
    
    @Option(help: "The path to save the experience")
    var experienceOut: String = "experience.pkl"

    mutating func run() throws {
        let logURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("self-play.log")
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
        
        let board = ZobristGoBoard(dimension: self.boardSize)
        
        let whitePlayer = createPlayer(for: .white)
        let blackPlayer = createPlayer(for: .black)
        let players: [Player: GoAgent] = [.white: whitePlayer, .black: blackPlayer]
        
        for _ in 0..<self.numGames {
            print("Game #\(self.numGames)")
            var game = GameState(board: board, nextPlayer: .black)
            
            while !game.isOver() {
                let move = players[game.nextPlayer]!.select(from: game)
                game = game.apply(move: move)
            }
        }
        
        print("FINISHED")
   
    }
    
    private func createPlayer(for color: Stone) -> GoAgent {
        let encoder = SimpleEncoder(boardDimension: self.boardSize)
        
        let agentModel = PolicyAgentModel(model: createModel(encoder: encoder), optimizer: optimizer)
        switch self.learningAgent {
        case "policy":
            return PolicyAgent(stone: color, encoder: encoder, model: agentModel)
        default:
            fatalError("Unsupported learning agent: \(self.learningAgent)")
        }
    }
    
    private func createModel(encoder: Encoder) -> Small {
        Small(encoder: encoder)
    }
    
    private var optimizer: Optimizer {
        SGD(learningRate: 0.1)
    }
    
}
