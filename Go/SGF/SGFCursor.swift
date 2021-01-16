//
//  SGFCursor.swift
//  Go
//
//  Created by Jae Seung Lee on 1/10/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation

class SGFCursor {
    var game: SGFGameTree?
    var gameTree: SGFGameTree?
    var node: SGFNode?
    var nodeNum: Int?
    var index: Int?
    var stack: [SGFGameTree]?
    var children: [SGFNode]?
    var atEnd: Bool?
    var atStart: Bool?
    
    init(gameTree: SGFGameTree) {
        self.game = gameTree
        reset()
    }
    
    func reset() -> Void {
        self.gameTree = self.game!
        self.nodeNum = 0
        self.index = 0
        self.stack = []
        self.node = self.gameTree?.nodelist![self.index!]
        self.setChildren()
        self.setFlags()
    }
    
    func setChildren() -> Void {
        if self.index! + 1 < self.gameTree!.nodelist!.count {
            self.children = Array(arrayLiteral: self.gameTree!.nodelist![self.index! + 1])
        } else {
            self.children = self.gameTree!.variations.map { gameTree in
                return gameTree.nodelist![0]
            }
        }
    }
    
    func setFlags() -> Void {
        if let gameTree = self.gameTree, let index = self.index {
            self.atEnd = gameTree.variations.isEmpty && (index + 1 == gameTree.nodelist!.count)
        } else {
            self.atEnd = false
        }
        
        if let stack = self.stack, let index = self.index {
            if stack.isEmpty && (index == 0) {
                self.atStart = true
            } else {
                self.atStart = false
            }
        }
    }
    
    func next(variationNum: Int = 0) -> SGFNode? {
        guard let index = self.index, let gameTree = self.gameTree else {
            return nil
        }
        
        if index + 1 < gameTree.nodelist!.count {
            if variationNum != 0 {
                return nil
            }
            self.index = self.index! + 1
        } else if !gameTree.variations.isEmpty {
            if variationNum < gameTree.variations.count {
                self.stack?.append(gameTree)
                self.gameTree = gameTree.variations[variationNum]
                self.index = 0
            } else {
                return nil
            }
        } else {
            return nil
        }
        
        self.node = self.gameTree?.nodelist![self.index!]
        self.nodeNum = self.nodeNum! + 1
        self.setChildren()
        self.setFlags()
        
        return self.node!
    }
    
    func previous() -> SGFNode? {
        if self.index! - 1 >= 0 {
            self.index = self.index! - 1
        } else if !self.stack!.isEmpty {
            self.gameTree = self.stack?.popLast()
            self.index = (self.gameTree?.nodelist?.count)! - 1
        } else {
            return nil
        }
        
        self.node = self.gameTree?.nodelist![self.index!]
        self.nodeNum = self.nodeNum! - 1
        self.setChildren()
        self.setFlags()
        
        return self.node!
    }
}
