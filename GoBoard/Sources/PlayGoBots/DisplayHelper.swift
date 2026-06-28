//
//  PrintBoard.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 6/28/26.
//

import GoBoard

struct DisplayHelper {
    
    private static let columns = "ABCDEFGHJKLMNOPQRST"

    private static func columnHeader(for dimension: Int) -> String {
        let startIdx = columns.startIndex
        let endIdx = columns.index(columns.startIndex, offsetBy: dimension)
        return String(columns[startIdx..<endIdx]).map { String($0) }.joined(separator: "  ")
    }
    
    static func display(board: GoBoard) {
        let dimension = board.dimension
        let columnHeader = columnHeader(for: dimension)
        
        for row in (1...dimension).reversed() {
            let bump = row <= 9 ? " " : ""
            var line = [String]()
            for col in (1...dimension) {
                if let stone = board.stone(at: Point(row: row, col: col)) {
                    line.append(stone.symbol)
                } else {
                    line.append(Stone.none.symbol)
                }
            }
            print("\(bump)\(row) \(line.joined(separator: ""))")
            
        }
        print("    \(columnHeader)")
    }
    
}

extension Stone {
    var symbol: String {
        switch self {
        case .none: return " . "
        case .black: return " x "
        case .white: return " o "
        }
    }
}
