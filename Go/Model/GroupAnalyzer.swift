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
    let lastPlay: Play?
    let location: Intersection
    let groups: Set<Group>
    var goBoard: GoBoard
    var possibleKo: Intersection?
    var locationsToRemove: Set<Intersection>?
    
    var unchangedGroups = Set<Group>()
    var playersGroupsToUpdate = Set<Group>()
    var opponentsGroupsToUpdate = Set<Group>()
    var groupsToRemove = Set<Group>()
    
    var intermediateGroups = Set<Group>()
    var nextGroups = Set<Group>()
    let removedStones: Set<Intersection>
    var isPlayable: Bool {
        return isEmpty() && !isKo() && !isSuicide()
    }
    
    var neighborsSameStone: Set<Intersection> {
        return GroupAnalyzer.neighbors(of: play, with: play.stone, goBoard: goBoard)
    }
    
    var neighborsOppositeStone: Set<Intersection>{
        return GroupAnalyzer.neighbors(of: play, with: play.stone == .Black ? .White : .Black, goBoard: goBoard)
    }
    
    var liberties: Set<Intersection> {
        return GroupAnalyzer.neighbors(of: play, with: nil, goBoard: goBoard)
    }
    
    var allNeighborsAreLiberties: Bool {
        return neighborsSameStone.count == 0 && neighborsOppositeStone.count == 0
    }
    
    // MARK:- Initializer
    init(play: Play, goBoard: GoBoard, groups: Set<Group>, lastPlay: Play?, removedStones: Set<Intersection>) {
        self.play = play
        self.goBoard = goBoard
        self.groups = groups
        self.lastPlay = lastPlay
        self.removedStones = removedStones
        
        self.location = Intersection(row: play.location.row, column: play.location.column, stone: play.stone, forbidden: false, isEye: false)
        
        (self.unchangedGroups, self.playersGroupsToUpdate, self.opponentsGroupsToUpdate, self.groupsToRemove) = GroupAnalyzer.split(groups, basedOn: play)
        
        self.intermediateGroups = GroupAnalyzer.generateIntermidiateGroupsGroups(unchangedGroups: self.unchangedGroups, playersGroupsToUpdate: self.playersGroupsToUpdate, opponentsGroupsToUpdate: self.opponentsGroupsToUpdate, play: play, goBoard: goBoard)
        
        (self.nextGroups, self.possibleKo, self.locationsToRemove) = GroupAnalyzer.process(self.groupsToRemove, intermediateGroups: self.intermediateGroups)
    }
    
    // MARK:- Methods
    static func neighbors(of play: Play, with status: Stone?, goBoard: GoBoard) -> Set<Intersection> {
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
    
    static private func merge(groups: Set<Group>, around play: Play, on goBoard: GoBoard) -> Group {
        var newLocations: Set = [play.location]
        var newLiberties = GroupAnalyzer.neighbors(of: play, with: nil, goBoard: goBoard)
        var newOppoenentLocations: Set = GroupAnalyzer.neighbors(of: play, with: play.stone == .Black ? .White : .Black, goBoard: goBoard)

        groups.forEach { (group) in
            newLocations.formUnion(group.locations)
            newOppoenentLocations.formUnion(group.opponentLocations)
            
            newLiberties.formUnion(group.liberties.filter { $0 != play.location })
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
    
    static private func newOpponentGroups(from currentOpponentGroups: Set<Group>, with location: Intersection) -> Set<Group> {
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
    
    private static func generateIntermidiateGroupsGroups(unchangedGroups: Set<Group>, playersGroupsToUpdate: Set<Group>, opponentsGroupsToUpdate: Set<Group>, play: Play, goBoard: GoBoard) -> Set<Group> {

        var tempGroup = unchangedGroups
        tempGroup.insert(GroupAnalyzer.merge(groups: playersGroupsToUpdate, around: play, on: goBoard))
        tempGroup.formUnion(GroupAnalyzer.newOpponentGroups(from: opponentsGroupsToUpdate, with: play.location))
        
        return tempGroup
    }
    
    static private func process(_ groupsToRemove: Set<Group>, intermediateGroups: Set<Group>) -> (Set<Group>, Intersection?, Set<Intersection>) {
        var locationsToRemove = Set<Intersection>()
        var possibleKo: Intersection?
        
        groupsToRemove.forEach { group in
            // May remove this check
            // They are from the opponent's groups with empty liberties
            if group.locations.count == 1 {
                // Try this as the next play to determine whether it is ko
                possibleKo = group.locations.first
            }
            
            locationsToRemove.formUnion(group.locations)
        }
        
        //print("locationsToRemove: \(locationsToRemove)")
        let nextGroups = generateNextGroups(from: intermediateGroups, byRemoving: locationsToRemove)
        
        return (nextGroups, possibleKo, locationsToRemove)
    }
    
    static private func findLocationsToRemove(from groups: Set<Group>) -> Set<Intersection> {
        var locationsToRemove = Set<Intersection>()
        groups.forEach { group in
            locationsToRemove.formUnion(group.locations)
        }
        return locationsToRemove
    }
    
    static private func generateNextGroups(from intermediateGroups: Set<Group>, byRemoving locationsToRemove: Set<Intersection>) -> Set<Group> {
        var nextGroups = Set<Group>()
        
        intermediateGroups.forEach { group in
            let locationsInGroup = group.opponentLocations.intersection(locationsToRemove)
            
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
        
        return  nextGroups
    }
    
    func isEmpty() -> Bool{
        return goBoard.status(row: play.location.row, column: play.location.column) == nil
    }
    
    func isSuicide() -> Bool {
        print("isSuicide = \(nextGroups.contains { $0.liberties.count == 0 })")
        return nextGroups.contains { $0.liberties.count == 0 }
    }
    
    func isKo() -> Bool {
        print("removedStones.contains(play.location) = \(removedStones.contains(play.location))")
        print("nextGroups.contains { $0.liberties.first == lastPlay!.location } = \(nextGroups.contains { $0.liberties.first == lastPlay!.location })")
        return removedStones.contains(play.location)
            && nextGroups.contains { $0.liberties.count == 1 && $0.liberties.first == lastPlay!.location }
    }
}
