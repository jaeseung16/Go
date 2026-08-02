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
    var experienceOut: String = "experience.safetensors"

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
        
        var whitePlayer = createPlayer(for: .white)
        var blackPlayer = createPlayer(for: .black)
        let players: [Player: GoAgent] = [.white: whitePlayer, .black: blackPlayer]
        
        let experienceCollector1 = ExperienceCollector()
        let experienceCollector2 = ExperienceCollector()
        
        var gameCount = 0
        while gameCount < self.numGames {
            if gameCount % 2 == 0 {
                whitePlayer.experienceCollector = experienceCollector1
                blackPlayer.experienceCollector = experienceCollector2
            } else {
                whitePlayer.experienceCollector = experienceCollector2
                blackPlayer.experienceCollector = experienceCollector1
            }
            
            experienceCollector1.beginEpisode()
            experienceCollector2.beginEpisode()
            
            print("Starting Game #\(gameCount)")
            var game = GameState(board: board, nextPlayer: .black)
            
            while !game.isOver() {
                let move = players[game.nextPlayer]!.select(from: game)
                game = game.apply(move: move)
            }
            
            let score = ScoringHelper(gameState: game).compute()
            print("score=\(score)")
            
            print("Finished Game #\(gameCount): Winner=\(String(describing: game.winner)), remainingLegalMoves=\(game.legalMoves)")
            
            if game.winner == .black {
                blackPlayer.experienceCollector?.completeEpisode(reward: MLXArray(1.0))
                whitePlayer.experienceCollector?.completeEpisode(reward: MLXArray(-1.0))
            } else {
                blackPlayer.experienceCollector?.completeEpisode(reward: MLXArray(-1.0))
                whitePlayer.experienceCollector?.completeEpisode(reward: MLXArray(1.0))
            }
            
            print("Collected \(experienceCollector1.states.count + experienceCollector2.states.count) experiences")
            
            gameCount += 1
        }
        
        let experienceBuffer = ExperienceBuffer.from(experiences: [experienceCollector1, experienceCollector2])
        
        let url = URL(fileURLWithPath: self.experienceOut)
        print("Saving experiences to \(url.path)")
        experienceBuffer.save(to: url)
        
        
        print("Collected \(experienceBuffer.states.shape[0]) experiences")
        
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
