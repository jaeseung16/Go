//
//  SGFNode.swift
//  Go
//
//  Created by Jae Seung Lee on 1/7/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation

class SGFNode: CustomStringConvertible {
    var data = [String: SGFProperty]()
    var order = [SGFProperty]()
    
    init(properties: [SGFProperty]) {
        properties.forEach { self.addProperty(property: $0) }
    }

    func addProperty(property: SGFProperty) -> Void {
        guard !data.contains(where: { arg0 -> Bool in
            let (key, _) = arg0
            return key == property.id
        }) else {
            return
        }
        
        data[property.id] = property
        order.append(property)
    }
    
    func makeProperty(id: String, values: [String]) -> SGFProperty {
        return SGFProperty(id: id, values: values)
    }
    
    var description: String {
        return "<SGFNode: data = \(data)>"
    }
}
