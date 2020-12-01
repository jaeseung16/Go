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
    var groups: Set<Group>
    var goBoard: GoBoard
    var possibleKo: Intersection?
    
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
                groups.remove(at: index!)
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
    
    func updateGroups() -> Void {
        goBoard.update(row: play.location.row, column: play.location.column, stone: play.stone)
        
        var newLocations = Set<Intersection>()
        newLocations.insert(location)
        
        if allNeighborsAreLiberties {
            // No neighboring locations are played
            // The trivial case?
            let newGroup = Group(id: play.id, stone: play.stone, locations: newLocations, liberties: liberties, oppenentLocations: neighborsOppositeStone)
            groups.insert(newGroup)
        } else {
            var groupsToUpdate = Set<Group>()
            var opponentGroupsToUpdate = Set<Group>()
            var groupsToRemoveFromGoBoard = Set<Group>()
            var newGroups = Set<Group>()
            
            // Get groups wherein liberties contain the play location
            // Groups for the player -> groupsToUpdate
            // Groups for the opponent -> opponentGroupsToUpdate
            groupsContaining(liberty: location).forEach { group in
                if group.stone == play.stone {
                    groupsToUpdate.insert(group)
                    print("Add to groupsToUpdate: group id = \(group.id)")
                } else {
                    opponentGroupsToUpdate.insert(group)
                    print("Add to opponentGroupsToUpdate: group id = \(group.id)")
                }
            }
            
            // Create a new group from groupsToUpdate
            // The play can connect more than one groups
            // The new group inherits all the locations from groupsToUpdate: newLocations already contains the play location
            // The new group inherits all the liberties except for the play location
            let newGroup = mergeGroups(groupsToUpdate)
            print("newGroup = \(newGroup)")
            newGroups.insert(newGroup)
            
            // Process opponentGroupsToUpdate
            // Make a new group with the play location moved from liberties to opponentLocations
            // If liberties become empty, the group may be captured so need to be removed -> groupsToRemoveFromGoBoard
            print("opponentGroupsToUpdate.count = \(opponentGroupsToUpdate.count)")
            newOpponentGroups(from: opponentGroupsToUpdate).forEach { newOpponentGroup in
                print("newOpponentGroup = \(newOpponentGroup)")
                if newOpponentGroup.liberties.isEmpty {
                    groupsToRemoveFromGoBoard.insert(newOpponentGroup)
                } else {
                    newGroups.insert(newOpponentGroup)
                }
            }
            
            // Remove old groups and add new groups
            removeGroups(opponentGroupsToUpdate)
            removeGroups(groupsToUpdate)
            
            groups.formUnion(newGroups)
            
            print("groups = \(groups)")
            
            // Process groupsToRemoveFromGoBoard
            print("groupsToRemoveFromGoBoard.count = \(groupsToRemoveFromGoBoard.count)")
            newGroups.removeAll()
            groupsToUpdate.removeAll()
            groupsToRemoveFromGoBoard.forEach { group in
                // May remove this check
                // They are from the opponent's groups with empty liberties
                if group.locations.count == 1 {
                    // Possible ko
                    // Later use
                    possibleKo = group.locations.first
                }
                for location in group.locations {
                    print("Remove location: \(location)")
                    goBoard.update(row: location.row, column: location.column, stone: nil)
                    
                    // Going through the player's groups
                    // Since the removed locations may become liberties
                    groups.forEach { aGroup in
                        if aGroup.opponentLocations.contains(location) {
                            var newOppoenentLocations = Set<Intersection>()
                            var newLiberties = Set<Intersection>()
                            
                            aGroup.opponentLocations.forEach { opponentLocation in
                                if opponentLocation == location {
                                    newLiberties.insert(opponentLocation)
                                } else {
                                    newOppoenentLocations.insert(opponentLocation)
                                }
                            }
                                
                            newLiberties.formUnion(aGroup.liberties)
                            
                            let newGroup = Group(id: aGroup.id, stone: aGroup.stone, locations: aGroup.locations, liberties: newLiberties, oppenentLocations: newOppoenentLocations)
                            
                            groupsToUpdate.insert(aGroup)
                            newGroups.insert(newGroup)
                        }
                    }
                }
                
                // Remove stones from the scene
                /*
                for play in plays {
                    let isInGroup = group.locations.contains { location -> Bool in
                        return location == play.location
                    }
          
                    //print("isInGroup = \(isInGroup) vs locations.contains = \(group.locations.contains(play.location))")
                    
                    if isInGroup && play.stone != play.stone {
                        print("Removing \(play))")
                        scene?.removeStones(at: "\(play.id)")
                    }
                }
                */
                    
            }
            
            // After processing groupsToRemoveFromGoBoard
            // Need to update groups
            print("groupsToUpdate.count = \(groupsToUpdate.count)")
            removeGroups(groupsToUpdate)
            groups.formUnion(newGroups)
        }
        
        print("groups = \(groups)")
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
