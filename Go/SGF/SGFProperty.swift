//
//  SGFProperty.swift
//  Go
//
//  Created by Jae Seung Lee on 1/10/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation

struct SGFProperty: CustomStringConvertible {
    var id: String
    var name: SGFToken
    var values: [String]?
    
    init() {
        id = SGFToken.NONE.rawValue
        name = SGFToken.NONE
    }
    
    init(id: String, values: [String], name: String? = nil) {
        self.id = id
        self.name = (name == nil ? SGFToken(rawValue: id) : SGFToken(rawValue: name!)) ?? SGFToken.UNKNOWN
        self.values = values
    }
    
    var description: String {
        return "<SGFProperty: id = \(id)), name = \(name), values = \(values ?? ["NONE"]))>"
    }
}
