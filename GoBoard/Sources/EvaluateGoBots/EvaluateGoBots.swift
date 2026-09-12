//
//  EvaluateGoBots.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 9/11/26.
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
struct EvaluateGoBots: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(commandName: "evaluate-bots",
              abstract: "Evaluate the performance of Go bots")
    }
    
    @Option(help: "Points added to white's score under area scoring. White wins ties.")
    var komi: Double = 7.5
    
    @Option(help: "The board size")
    var boardSize: Int = 19
    
    @Option(help: "The first agent to play")
    var agent1: String
    
    @Option(help: "The second agent to play")
    var agent2: String
    
    @Option(help: "The number of games to play")
    var games: Int
    
    @Option(help: "The output file to write the results to")
    var output: String

    @Flag(help: "Whether to play in verbose mode")
    var verbose = false
    
    func run() throws {
        // Route all GoAgent/GoBoard logs to a dedicated file so the terminal
        // display stays clean.
        let logURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("evaluate-go-bots.log")
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
        print("Playing \(games) games between \(agent1) and \(agent2): boardSize=\(boardSize), komi=\(komi)")
        
        let agentModel1 = try createAgentModel(from: agent1)
        let agentModel2 = try createAgentModel(from: agent2)
        
        var results: [Player: Int] = [:]
        var isAgent1Black: Bool = false
        for game in 1...games {
            print("Game \(game)")
            
            let blackModel = isAgent1Black ? agentModel1 : agentModel2
            let whiteModel = isAgent1Black ? agentModel2 : agentModel1
            
            let blackPlayer = createPlayer(for: .black, with: blackModel, encoder: blackModel.encoder)
            let whitePlayer = createPlayer(for: .white, with: whiteModel, encoder: whiteModel.encoder)
            
            let players: [Player: GoAgent] = [.white: whitePlayer, .black: blackPlayer]
            
            if let winner = playGame(with: players, on: ZobristGoBoard(dimension: self.boardSize)) {
                results[winner, default: 0] += 1
            } else {
                print("Somehow there was no winner")
            }
            
            isAgent1Black.toggle()
        }
        
        print("\nResults: \(results)")
        
    }
    
    private func createAgentModel(from agentFileName: String) throws -> GoAgentModel {
        let url = URL(fileURLWithPath: agentFileName)
        let (arrays, metadata) = try MLX.loadArraysAndMetadata(url: url)
        
        let encoderName = metadata["encoder"] ?? ""
        let encoder = createEncoder(encoderName)
        
        let networkName = metadata["network"] ?? ""
        let network = createNetwork(networkName, encoder: encoder)
        
        let parameters = ModuleParameters.unflattened(arrays)
        network.update(parameters: parameters)
        
        let agentModelName = metadata["agentModel"] ?? ""
        return try createAgentModel(agentModelName, network: network)
    }
    
    private func createEncoder(_ name: String) -> GoBoardEncoder {
        if let encoderName = GoBoardEncoderName(rawValue: name) {
            return GoBoardEncoderFactoryImpl().create(encoderName, boardDimension: self.boardSize)
        }
        fatalError("Unsupported encoder: \(name)")
    }
    
    private func createNetwork(_ name: String, encoder: GoBoardEncoder) -> GoNetwork {
        if let networkName = GoNetworkName(rawValue: name) {
            return GoNetworkFactoryImpl().create(networkName, with: encoder)
        }
        fatalError("Unsupported netowrk: \(name)")
    }
    
    private func createAgentModel(_ name: String, network: GoNetwork) throws -> GoAgentModel {
        if let agentModelName = GoAgentModelName(rawValue: name) {
            return try GoAgentModelFactoryImpl().create(agentModelName, with: network)
        }
        fatalError("Unsupported learning agent: \(name)")
    }
    
    private func playGame(with players: [Player: GoAgent], on board: GoBoard) -> Player? {
        var game = GameState(board: board, nextPlayer: .black)
        
        while !game.isOver() {
            if verbose {
                print("\u{001B}[2J")
                DisplayHelper.display(board: game.board)
            }
            
            let move = players[game.nextPlayer]!.select(from: game)
            
            if verbose {
                DisplayHelper.display(move: move, player: game.nextPlayer)
            }
            
            game = game.apply(move: move)
        }
        
        if verbose {
            DisplayHelper.display(board: game.board)
        }
        
        return game.winner(komi: self.komi)
    }
    
    private func createPlayer(for color: Stone, with agentModel: GoAgentModel, encoder: GoBoardEncoder) -> GoAgent {
        // TODO: - May need GoAgentFactory
        return PolicyAgent(stone: color, encoder: encoder, model: agentModel)
    }
    
}
