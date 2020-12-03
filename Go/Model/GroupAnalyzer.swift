//
//  GroupAnalyzer.swift
//  Go
//
//  Created by Jae Seung Lee on 11/28/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

class GroupAnalyzer {
    // MARK:- Properties
    let play: Play
    let location: Intersection
    let groups: Set<Group>
    var goBoard: GoBoard
    var possibleKo: Intersection?
    var locationsToRemove: Set<Intersection>?
    
    var unchangedGroups = Set<Group>()
    var playersGroupsToUpdate = Set<Group>()
    var opponentsGroupsToUpdate = Set<Group>()
    var groupsToRemove = Set<Group>()
    
    var intermidiateGroups = Set<Group>()
    var nextGroups = Set<Group>()
    var isPlayable: Bool?
    
    var neighborsSameStone: Set<Intersection> {
        return neighbors(of: play, with: play.stone)
    }
    
    var neighborsOppositeStone: Set<Intersection>{
        return neighbors(of: play, with: play.stone == .Black ? .White : .Black)
    }
    
    var liberties: Set<Intersection> {
        return neighbors(of: play, with: nil)
    }
    
    var allNeighborsAreLiberties: Bool {
        return neighborsSameStone.count == 0 && neighborsOppositeStone.count == 0
    }
    
    // MARK:- Initializer
    init(play: Play, goBoard: GoBoard, groups: Set<Group>) {
        self.play = play
        self.goBoard = goBoard
        self.groups = groups
        
        self.location = Intersection(row: play.location.row, column: play.location.column, stone: play.stone, forbidden: false, isEye: false)
        
        (self.unchangedGroups, self.playersGroupsToUpdate, self.opponentsGroupsToUpdate, self.groupsToRemove) = GroupAnalyzer.split(groups, basedOn: play)
    }
    
    // MARK:- Methods
    func neighbors(of play: Play, with status: Stone?) -> Set<Intersection> {
        var neighbors = Set<Intersection>()
        
        for neighbor in Neighbor.allCases {
            switch neighbor {
            case .up:
                if play.location.row > 0 && status == goBoard.status(row: play.location.row - 1, column: play.location.column) {
                    neighbors.insert(Intersection(row: play.location.row - 1, column: play.location.column, stone: status, forbidden: false, isEye: false))
                }
            case .down:
                if play.location.row < goBoard.size - 1 && status == goBoard.status(row: play.location.row + 1, column: play.location.column) {
                    neighbors.insert(Intersection(row: play.location.row + 1, column: play.location.column, stone: status, forbidden: false, isEye: false))
                }
            case .left:
                if play.location.column > 0 && status == goBoard.status(row: play.location.row, column: play.location.column - 1) {
                    neighbors.insert(Intersection(row: play.location.row, column: play.location.column - 1, stone: status, forbidden: false, isEye: false))
                }
            case .right:
                if play.location.column < goBoard.size - 1  && status == goBoard.status(row: play.location.row, column: play.location.column + 1) {
                    neighbors.insert(Intersection(row: play.location.row, column: play.location.column + 1, stone: status, forbidden: false, isEye: false))
                }
            }
        }
        
        return neighbors
    }
    
    func groupsContaining(liberty: Intersection) -> Set<Group> {
        return self.groups.filter { $0.liberties.contains(liberty) }
    }
    
    func groupsContaining(location: Intersection) -> Set<Group> {
        return self.groups.filter { $0.locations.contains(location) }
    }
    
    func groupsContaining(opponentLocation: Intersection) -> Set<Group> {
        return self.groups.filter { $0.opponentLocations.contains(opponentLocation) }
    }
    
    func mergeGroups(_ groups: Set<Group>) -> Group {
        var newLocations: Set = [location]
        var newLiberties: Set = liberties
        var newOppoenentLocations: Set = neighborsOppositeStone

        groups.forEach { (group) in
            newLocations.formUnion(group.locations)
            newOppoenentLocations.formUnion(group.opponentLocations)
            
            newLiberties.formUnion(group.liberties.filter { $0 != location })
        }

        return Group(id: play.id, stone: play.stone, locations: newLocations, liberties: newLiberties, oppenentLocations: newOppoenentLocations)
    }
    
    func removeGroups(_ groupsToRemove: Set<Group>) -> Void {
        groupsToRemove.forEach { groupToRemove in
            let index = groups.firstIndex { group -> Bool in
                return groupToRemove.id == group.id
            }
            
            if index != nil {
                nextGroups.remove(at: index!)
            } else {
                print("removeGroups: groups \(groups) does not contain \(groupToRemove)")
            }
        }
    }
    
    func newOpponentGroups(from currentOpponentGroups: Set<Group>) -> Set<Group> {
        var nextGroups = Set<Group>()
        currentOpponentGroups.forEach { currentGroup in
            var newOppoenentLocations = currentGroup.opponentLocations
            newOppoenentLocations.insert(location)
            
            let newLiberties = currentGroup.liberties.filter { $0 != location }
            
            nextGroups.insert(Group(id: currentGroup.id, stone: currentGroup.stone, locations: currentGroup.locations, liberties: newLiberties, oppenentLocations: newOppoenentLocations))
        }
        return nextGroups
    }
    
    static func split(_ inGroups: Set<Group>, basedOn play: Play) -> (Set<Group>, Set<Group>, Set<Group>, Set<Group>) {
        var playerGroups = Set<Group>()
        var oppoentGroups = Set<Group>()
        var opponentGroupsToRemove = Set<Group>()
        var otherGroups = Set<Group>()
        
        inGroups.forEach { group in
            if group.liberties.contains(play.location) {
                if group.stone == play.stone {
                    playerGroups.insert(group)
                    print("Add to playersGroupsToUpdate: group id = \(group.id)")
                } else if group.liberties.count == 1 {
                    opponentGroupsToRemove.insert(group)
                    print("Add to groupsToRemove: group id = \(group.id)")
                } else {
                    oppoentGroups.insert(group)
                    print("Add to opponentsGroupsToUpdate: group id = \(group.id)")
                }
            } else {
                otherGroups.insert(group)
                print("Add to unchangedGroups: group id = \(group.id)")
            }
        }
        
        return (otherGroups, playerGroups, oppoentGroups, opponentGroupsToRemove)
    }
    
    func generateIntermidiateGroupsGroups() -> Void {
        intermidiateGroups.formUnion(unchangedGroups)
        intermidiateGroups.insert(mergeGroups(playersGroupsToUpdate))
        intermidiateGroups.formUnion(newOpponentGroups(from: opponentsGroupsToUpdate))
    }
    
    func processGroupsToRemove() -> Void {
        locationsToRemove = Set<Intersection>()
        groupsToRemove.forEach { group in
            // May remove this check
            // They are from the opponent's groups with empty liberties
            if group.locations.count == 1 {
                // Try this as the next play to determine whether it is ko
                possibleKo = group.locations.first
            }
            
            locationsToRemove?.formUnion(group.locations)
        }
        
        locationsToRemove!.forEach { location in
            print("Remove location: \(location)")
            goBoard.update(row: location.row, column: location.column, stone: nil)
        }
        
        intermidiateGroups.forEach { group in
            let locationsInGroup = group.opponentLocations.intersection(locationsToRemove!)
            
            if locationsInGroup.count > 0 {
                let newOppoenentLocations = group.opponentLocations.subtracting(locationsInGroup)
                var newLiberties = group.liberties
                newLiberties.formUnion(locationsInGroup)
                
                let newGroup = Group(id: group.id, stone: group.stone, locations: group.locations, liberties: newLiberties, oppenentLocations: newOppoenentLocations)
                
                nextGroups.insert(newGroup)
            } else {
                nextGroups.insert(group)
            }
           
        }
    }
    
    func isPlayable(stone: Stone, column: Int, row: Int) -> Bool {
        print("isPlayable: \(stone) @ row = \(row), column = \(column)")
        let newLocation = Intersection(row: row, column: column, stone: stone, forbidden: false, isEye: false)
        
        
        var canPlay = goBoard.status(row: row, column: column) == nil
        
        // TODO: Chekc ko
        // Is possibleKo really ko?
        if canPlay && (possibleKo != nil) && (possibleKo == newLocation) {
            print("ko = \(String(describing: possibleKo))")
            canPlay = false
        }
        
        // TODO: Check suicides
        // Need to exclude if there are captures
        for group in groups {
            if group.stone == stone && group.liberties.count == 1 && group.liberties.contains(newLocation) {
                print("group = \(group)")
                canPlay = false
                break
            }
        }
        
        // Need to check ko
        // let status = goBoard.status(row: row, column: column)
        // let play = Play(id: playNumber, row: row, column: column, stone: stone)
        return canPlay
    }
}
