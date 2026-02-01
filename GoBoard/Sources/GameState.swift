//
//  GameState.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 1/4/26.
//

public class GameState {
    
    private let board: GoBoard
    private var nextPlayer: Player
    private let previousState: GameState?
    private let lastMove: Move?
    
    public init(board: GoBoard, nextPlayer: Player, previousState: GameState? = nil, lastMove: Move? = nil) {
        self.board = board
        self.nextPlayer = nextPlayer
        self.lastMove = lastMove
        
        // TODO: preivousState
        self.previousState = previousState
    }
    
    public apply(move: Move) -> GameState {
        let nextBoard = board.copy()
        
        if move.isPlay {
            let point = move.point {
                nextBoard.place(stone: self.nextPlayer, at: move.point)
            }
        }
        
        return GameState(board: nextBoard, nextPlayer: nextPlayer.other, previousState: self, lastMove: move)
    }
    
    public static func newGame(boardSize: Int) -> GameState {
        return GameState(board: ZobristGoBoard(dimension: boardSize), nextPlayer: .black)
    }
    
    public func isSelfCapture(_ move: Move) -> Bool {
        guard move.isPlay else { return false }
        return board.isSelfCapture(move)
        
    }

    public var situation: (Player, GoBoard) {
        return (nextPlayer, board)
    }
}

/*

def __init__(self, board, next_player, previous, move):
    self.board = board
    self.next_player = next_player
    self.previous_state = previous
    if previous is None:
        self.previous_states = frozenset()
    else:
        self.previous_states = frozenset(previous.previous_states | {(previous.next_player, previous.board.zobrist_hash())})
    self.last_move = move

def does_move_violate_ko(self, player, move):
    if not move.is_play:
        return False
    if not self.board.will_capture(player, move.point):
        return False
    next_board = copy.deepcopy(self.board)
    next_board.place_stone(player, move.point)
    next_situation = (player.other, next_board.zobrist_hash())
    return next_situation in self.previous_states

def is_valid_move(self, move):
    if self.is_over():
        return False
    if move.is_pass or move.is_resign:
        return True
    return (self.board.get(move.point) is None and
            not self.is_move_self_capture(self.next_player, move) and
            not self.does_move_violate_ko(self.next_player, move))

def is_over(self):
    if self.last_move is None:
        return False
    if self.last_move.is_resign:
        return True
    second_last_move = self.previous_state.last_move
    if second_last_move is None:
        return False
    return self.last_move.is_pass and second_last_move.is_pass

def legal_moves(self):
    if self.is_over():
        return []
    moves = []
    for row in range(1, self.board.num_rows + 1):
        for col in range(1, self.board.num_cols + 1):
            move = Move.play(Point(row, col))
            if self.is_valid_move(move):
                moves.append(move)
    moves.append(Move.pass_turn())
    moves.append(Move.resign())

    return moves

def winner(self):
    if not self.is_over():
        return None
    if self.last_move.is_resign:
        return self.next_player
    game_result = compute_game_result(self)
    return game_result.winner
 */
