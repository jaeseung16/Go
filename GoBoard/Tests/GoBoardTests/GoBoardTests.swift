import Testing
@testable import GoBoard

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
                print("\(move): \(table[move])")
            }
        }
    }
    
    #expect(table.count == 19 * 19 * 3)
            
}
