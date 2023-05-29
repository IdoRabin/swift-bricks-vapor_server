//
//  BrickSettings.swift
//  Bricks
//
//  Created by Ido Rabin on 11/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Cocoa
import Fluent
import MNUtils

final class BrickSettings : Codable, MNUIDable {
    
    
    var drawingSnapToGrid : Bool = true
    var drawingGridSize : CGFloat = 10.0
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case drawingSnapToGrid = "drawingSnapToGrid"
        case drawingGridSize = "drawingGridSize"
        
        var fieldKey : FieldKey {
            return .string(self.rawValue)
        }
    }
    
    var id: UUIDv5?
    
    var mnUID : MNUID? {
        guard let uid = self.id else {
            return nil
        }
        return MNUID(uidV5: uid, type: MNUIDTypes.docsettings)
    }
    
    // Vapor Model requires implementing an empty init()
    init() {
        id = UUID()
    }
}

