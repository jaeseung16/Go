//
//  GoString.swift
//  GoBoard
//
//  Created by Jae Seung Lee on 12/14/25.
//

public struct GoString: Equatable, Hashable {
    
    public var color: Stone
    public var stones: Set<Point>
    public var liberties: Set<Point>
    
    public var numberOfLiberties: Int {
        return liberties.count
    }
    
    public func without(liberty: Point) -> GoString {
        let newLiberties = liberties.subtracting([liberty])
        return GoString(color: color, stones: stones, liberties: newLiberties)
    }
    
    public func with(liberty: Point) -> GoString {
        let newLiberties = liberties.union([liberty])
        return GoString(color: color, stones: stones, liberties: newLiberties)
    }
    
    public func merged(with other: GoString) -> GoString {
        guard self.color == other.color else {
            fatalError("Can't merge strings of different colors.")
        }
        let newStones = stones.union(other.stones)
        let newLiberties = liberties.union(other.liberties).subtracting(newStones)
        return GoString(color: color, stones: newStones, liberties: newLiberties)
    }
    
}
