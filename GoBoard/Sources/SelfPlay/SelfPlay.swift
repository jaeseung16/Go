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
    // .xcodebuild/Build/Products/Debug/SelfPlay --board-size 9 --num-games 1000 --agent-name policy --network-name small --encoder simple --experience-out experience.safetensors

    static var configuration: CommandConfiguration {
        .init(commandName: "self-play",
              abstract: "Make a bot play Go against itself")
    }

    @Option(help: "Points added to white's score under area scoring. White wins ties.")
    var komi: Double = 7.5
    
    @Option(help: "The board size")
    var boardSize: Int = 19
    
    @Option(help: "The number of games to play")
    var numGames: Int = 1
    
    @Option(help: "The name of a learning agent")
    var agentName: String = "policy"
    
    @Option(help: "The name of the network used in an agent")
    var networkName: String = "small"
    
    @Option(help: "The weights of the network used in an agent")
    var weights: String?
    
    @Option(help: "The name of an encoder")
    var encoder: String = "simple"

    @Option(help: "The probability of playing a uniformly random move instead of following the policy")
    var temperature: Float = 0.0

    @Option(help: "The path to save the experience")
    var experienceOut: String = "experience.safetensors"

    func validate() throws {
        guard (0...1).contains(self.temperature) else {
            throw ValidationError("temperature must be between 0 and 1, got \(self.temperature)")
        }
        guard self.komi.isFinite else {
            throw ValidationError("komi must be a finite number, got \(self.komi)")
        }
    }

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
        
        let board = createBoard()
        let encoder = createEncoder()
        let network = createNetwork(encoder: encoder)
        let agentModel = createAgentModel(network: network, optimizer: optimizer)
        
        // TODO: Naming convention?
        if let weights {
            // Load
            let url = URL(fileURLWithPath: weights)
            try agentModel.load(from: url)
        } else {
            // Save
            let url = URL(fileURLWithPath: "\(self.networkName).safetensors")
            try agentModel.save(to: url)
        }
        
        var whitePlayer = createPlayer(for: .white, with: agentModel, encoder: encoder)
        var blackPlayer = createPlayer(for: .black, with: agentModel, encoder: encoder)
        let players: [Player: GoAgent] = [.white: whitePlayer, .black: blackPlayer]
        
        let experienceCollector1 = ExperienceCollector(stateShape: encoder.shape)
        let experienceCollector2 = ExperienceCollector(stateShape: encoder.shape)
        
        var gameCount = 0
        var blackWins = 0
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
            
            let score = ScoringHelper(gameState: game, komi: self.komi).compute()
            print("score=\(score)")
            
            let winner = game.winner(komi: self.komi)
            print("Finished Game #\(gameCount): Winner=\(String(describing: winner)), remainingLegalMoves=\(game.legalMoves)")
            
            if winner == .black {
                blackWins += 1
                blackPlayer.experienceCollector?.completeEpisode(reward: 1)
                whitePlayer.experienceCollector?.completeEpisode(reward: -1)
            } else {
                blackPlayer.experienceCollector?.completeEpisode(reward: -1)
                whitePlayer.experienceCollector?.completeEpisode(reward: 1)
            }
            
            print("Collected \(experienceCollector1.count + experienceCollector2.count) experiences")
            
            gameCount += 1
        }
        
        guard let experienceBuffer = ExperienceBuffer.merging([experienceCollector1.makeBuffer(),
                                                               experienceCollector2.makeBuffer()]) else {
            throw ValidationError("The collectors disagree about the state shape")
        }
        
        let url = URL(fileURLWithPath: self.experienceOut)
        print("Saving experiences to \(url.path)")
        try SafetensorsExperienceStore().write(experienceBuffer, to: url)
        
        print("Collected \(experienceBuffer.count) experiences")
        print("Black won \(blackWins) of \(self.numGames) games with komi \(self.komi)")
        
        print("FINISHED")
   
    }
    
    private func createBoard() -> GoBoard {
        ZobristGoBoard(dimension: self.boardSize)
    }
    
    private func createEncoder() -> GoBoardEncoder {
        switch self.encoder {
        case "simple":
            return SimpleEncoder(boardDimension: self.boardSize)
        default:
            fatalError("Unsupported encoder: \(self.encoder)")
        }
    }
    
    private func createPlayer(for color: Stone, with agentModel: GoAgentModel, encoder: GoBoardEncoder) -> GoAgent {
        switch self.agentName {
        case "policy":
            // Set the temperature here, while the concrete type is still in hand: it is a
            // PolicyAgent property, and the GoAgent return type erases it.
            let agent = PolicyAgent(stone: color, encoder: encoder, model: agentModel, temperature: self.temperature)
            return agent
        default:
            fatalError("Unsupported learning agent: \(self.agentName)")
        }
    }
    
    private func createNetwork(encoder: GoBoardEncoder) -> some GoNetwork {
        switch self.networkName {
        case "small":
            return Small(encoder: encoder)
        default:
            fatalError("Unsupported netowrk: \(self.networkName)")
        }
    }
    
    private func createAgentModel(network: GoNetwork, optimizer: Optimizer) -> GoAgentModel {
        switch self.agentName {
        case "policy":
            return PolicyAgentModel<Small>(network: network as! Small, optimizer: optimizer)
        default:
            fatalError("Unsupported learning agent: \(self.agentName)")
        }
    }
    
    private var optimizer: Optimizer {
        SGD(learningRate: 0.1)
    }
    
}
