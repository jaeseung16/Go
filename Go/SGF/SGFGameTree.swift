//
//  SGFGameTree.swift
//  Go
//
//  Created by Jae Seung Lee on 1/10/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation

class SGFGameTree: CustomStringConvertible {
    var nodelist: [SGFNode]?
    var variations: [SGFGameTree]
    
    init(nodes: [SGFNode]? = nil, variations: [SGFGameTree]? = nil) {
        self.nodelist = nodes
        self.variations = variations ?? [SGFGameTree]()
    }
    
    var description: String {
        return "<SGFGameTree: nodelist = \(String(describing: nodelist)), variations.count = \(variations.count)>"
    }
    
    var mainline: SGFGameTree {
        if !self.variations.isEmpty {
            return SGFGameTree(nodes: self.nodelist! + self.variations[0].mainline.nodelist!)
        } else {
            return self
        }
    }
    
    func makeNode(properties: [SGFProperty]) -> SGFNode {
        return SGFNode(properties: properties)
    }
    
    var cursor: SGFCursor {
        return SGFCursor(gameTree: self)
    }
    
    func propertySearch(id: String, getAll: Bool = false) -> SGFGameTree {
        var matches = [SGFNode]()
        
        if let nodelist = nodelist {
            for node in nodelist {
                if node.data[id] != nil {
                    matches.append(node)
                    if !getAll {
                        break
                    }
                } else {
                    for variation in self.variations {
                        matches = matches + variation.propertySearch(id: id, getAll: getAll).nodelist!
                        if !getAll {
                            break
                        }
                    }
                }
            }
        }
        
        return SGFGameTree(nodes: matches)
    }
}
