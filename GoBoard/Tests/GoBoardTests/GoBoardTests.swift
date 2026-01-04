import Testing
@testable import GoBoard

@Suite struct GoBoardTests {
    @Test func generateZobristHash() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        

        guard let max = UInt("7fffffffffffffff", radix:16) else {
            print("Can't parse max value")
            return
        }
        
        var table = [Move: UInt]()
        
        for row in 1..<20 {
            for col in 1..<20 {
                for stone in Stone.allCases {
                    let move = Move(player: Player.from(stone: stone), point: Point(row: row, col: col))
                    table[move] = UInt.random(in: 0...max)
                    print("\(move): \(String(describing: table[move]))")
                }
            }
        }
        
        #expect(table.count == 19 * 19 * 3)
                
    }

    @Test func testCapture() async throws {
        let board = ZobristGoBoard()
        board.place(stone: .black, at: Point(row: 2, col: 2))
        board.place(stone: .white, at: Point(row: 1, col: 2))
        
        #expect(board.stone(at: Point(row: 2, col: 2)) != nil && board.stone(at: Point(row: 2, col: 2))! == .black)
        
        board.place(stone: .white, at: Point(row: 2, col: 1))
        
        #expect(board.stone(at: Point(row: 2, col: 2)) != nil && board.stone(at: Point(row: 2, col: 2))! == .black)
        
        board.place(stone: .white, at: Point(row: 2, col: 3))
        
        #expect(board.stone(at: Point(row: 2, col: 2)) != nil && board.stone(at: Point(row: 2, col: 2))! == .black)
        
        board.place(stone: .white, at: Point(row: 3, col: 2))
        
        #expect(board.stone(at: Point(row: 2, col: 2)) == nil)
    }

    @Test func testCaptureTwoStones() async throws {
        let board = ZobristGoBoard()
        
        board.place(stone: .black, at: Point(row: 2, col: 2))
        board.place(stone: .black, at: Point(row: 2, col: 3))
        board.place(stone: .white, at: Point(row: 1, col: 2))
        board.place(stone: .white, at: Point(row: 1, col: 3))
        
        #expect(board.stone(at: Point(row: 2, col: 2)) != nil && board.stone(at: Point(row: 2, col: 2))! == .black)
        #expect(board.stone(at: Point(row: 2, col: 3)) != nil && board.stone(at: Point(row: 2, col: 3))! == .black)
        
        board.place(stone: .white, at: Point(row: 3, col: 2))
        board.place(stone: .white, at: Point(row: 3, col: 3))
        
        #expect(board.stone(at: Point(row: 2, col: 2)) != nil && board.stone(at: Point(row: 2, col: 2))! == .black)
        #expect(board.stone(at: Point(row: 2, col: 3)) != nil && board.stone(at: Point(row: 2, col: 3))! == .black)
        
        board.place(stone: .white, at: Point(row: 2, col: 1))
        board.place(stone: .white, at: Point(row: 2, col: 4))
        
        #expect(board.stone(at: Point(row: 2, col: 2)) == nil)
        #expect(board.stone(at: Point(row: 2, col: 3)) == nil)
    }

    @Test func testCaptureIsNotSuicide() async throws {
        let board = ZobristGoBoard()
        board.place(stone: .black, at: Point(row: 1, col: 1))
        board.place(stone: .black, at: Point(row: 2, col: 2))
        board.place(stone: .black, at: Point(row: 1, col: 3))
        board.place(stone: .white, at: Point(row: 2, col: 1))
        board.place(stone: .white, at: Point(row: 1, col: 2))
        
        #expect(board.stone(at: Point(row: 1, col: 1)) == nil)
        #expect(board.stone(at: Point(row: 2, col: 1)) != nil && board.stone(at: Point(row: 2, col: 1))! == .white)
        #expect(board.stone(at: Point(row: 1, col: 2)) != nil && board.stone(at: Point(row: 1, col: 2))! == .white)
        
    }
    
    @Test func testRemoveLiberties() async throws {
        let board = ZobristGoBoard()
        board.place(stone: .black, at: Point(row: 3, col: 3))
        board.place(stone: .white, at: Point(row: 2, col: 2))
        let whiteString = board.goString(at: Point(row: 2, col: 2))
        
        #expect(
            whiteString != nil &&
            whiteString!.liberties == [Point(row: 2, col: 3), Point(row: 2, col: 1), Point(row: 1, col: 2), Point(row: 3, col: 2)]
        )
        
        board.place(stone: .black, at: Point(row: 3, col: 2))
        let updatedWhiteString = board.goString(at: Point(row: 2, col: 2))
        
        #expect(
            updatedWhiteString != nil &&
            updatedWhiteString!.liberties == [Point(row: 2, col: 3), Point(row: 2, col: 1), Point(row: 1, col: 2)]
        )
    }
    
    @Test func testEmptyTriangle() async throws {
        let board = ZobristGoBoard()
        board.place(stone: .black, at: Point(row: 1, col: 1))
        board.place(stone: .black, at: Point(row: 1, col: 2))
        board.place(stone: .black, at: Point(row: 2, col: 2))
        board.place(stone: .white, at: Point(row: 2, col: 1))
        
        let blackString = board.goString(at: Point(row: 1, col: 1))
        
        #expect(
            blackString != nil &&
            blackString!.liberties == [Point(row: 3, col: 2), Point(row: 2, col: 3), Point(row: 1, col: 3)]
        )
    }

    @Test func testSelfCapture() async throws {
        // ooo..
        // x.xo.
        
        let board = ZobristGoBoard()
        board.place(stone: .black, at: Point(row: 1, col: 1))
        board.place(stone: .black, at: Point(row: 1, col: 3))
        board.place(stone: .white, at: Point(row: 2, col: 1))
        board.place(stone: .white, at: Point(row: 2, col: 2))
        board.place(stone: .white, at: Point(row: 2, col: 3))
        board.place(stone: .white, at: Point(row: 1, col: 4))
        
        #expect(board.isSelfCapture(Move(player: .black, point: Point(row: 1, col: 2))))
    }
    
    @Test func testNotSelfCapture() async throws {
        // o.o..
        // x.xo.
        
        let board = ZobristGoBoard()
        board.place(stone: .black, at: Point(row: 1, col: 1))
        board.place(stone: .black, at: Point(row: 1, col: 3))
        board.place(stone: .white, at: Point(row: 2, col: 1))
        board.place(stone: .white, at: Point(row: 2, col: 3))
        board.place(stone: .white, at: Point(row: 1, col: 4))
        
        #expect(!board.isSelfCapture(Move(player: .black, point: Point(row: 1, col: 2))))
    }
    
    @Test func testNotSelfCaptureIsOtherCapture() async throws {
        // xx...
        // oox..
        // x.o..
        
        let board = ZobristGoBoard()
        board.place(stone: .black, at: Point(row: 3, col: 1))
        board.place(stone: .black, at: Point(row: 3, col: 2))
        board.place(stone: .black, at: Point(row: 2, col: 3))
        board.place(stone: .black, at: Point(row: 1, col: 1))
        board.place(stone: .white, at: Point(row: 2, col: 1))
        board.place(stone: .white, at: Point(row: 2, col: 2))
        board.place(stone: .white, at: Point(row: 1, col: 3))
        
        #expect(!board.isSelfCapture(Move(player: .black, point: Point(row: 1, col: 2))))
    }
    
}
