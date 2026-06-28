//
//  PrintBoard.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 6/28/26.
//

import GoBoard

class DisplayHelper {
    
    private static let COLS = "ABCDEFGHJKLMNOPQRST"
    private static let STONE_TO_CHAR: [Stone: String] = [
        .none: " . ",
        .black: " x ",
        .white: " o "
    ]

    private static func columns(for dimension: Int) -> String {
        let startIdx = COLS.index(COLS.startIndex, offsetBy: 0)
        let endIdx = COLS.index(COLS.startIndex, offsetBy: dimension)
        
        return String(COLS[startIdx..<endIdx]).map { String($0) }.joined(separator: "  ")
    }
    
    func display(board: GoBoard) {
        let dimension = board.dimension
        let columns = Self.columns(for: dimension)
        
        for row in (1...dimension).reversed() {
            let bump = row <= 9 ? " " : ""
            var line = [String]()
            for col in (1...dimension) {
                if let stone = board.stone(at: Point(row: row, col: col)) {
                    line.append(Self.STONE_TO_CHAR[stone]!)
                } else {
                    line.append(Self.STONE_TO_CHAR[.none]!)
                }
            }
            print("\(bump)\(row) \(line.joined(separator: ""))")
            
        }
            
        print("    \(columns)")
        
    }
    
}
