//
//  BrickStats.swift
//  Bricks
//
//  Created by Ido Rabin on 20/07/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Foundation
import Fluent
import MNUtils

// Vapor requires final class
final class BrickStats: Codable, MNUIDable {
    
    // MARK: fields
    var sessionCount : UInt = 1
    var indexingCount : UInt = 0
    var modificationsCount : UInt = 0
    var savesCount : UInt = 0
    var savesByCommandCount : UInt = 0
    var loadsCount : UInt = 0
    var loadsTimings = AverageAccumulator(named: "loadsTimings", persistentInFile: false, maxSize: 50)
    var id: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case sessionCount = "sessionCount"
        case indexingCount = "indexingCount"
        case modificationsCount = "modificationsCount"
        case savesCount = "savesCount"
        case savesByCommandCount = "savesByCommandCount"
        case loadsCount = "loadsCount"
        case loadsTimings = "loadsTimings"
        
        var fieldKey : FieldKey {
            return .string(self.rawValue)
        }
    }
    
    // MARK: Computed properties
    var mnUID : MNUID? {
        guard let uid = self.id else {
            return nil
        }
        return MNUID(uidV5: uid, type: MNUIDTypes.docstats)
    }
    
    var autosavesCount : Int {
        return Int(savesCount) - Int(savesByCommandCount)
    }
    
    // Empty init required by Fluent "Model"
    required init() {
        
    }
    
    var statsDisplayDictionary : [String:String] {
        get {
            var result : [String:String] = [:]
            result["sessions"] = String(sessionCount)
            result["indexing"] = String(indexingCount)
            result["savesCount"] = String(savesCount)
            result["savesByCommandCount"] = String(savesByCommandCount)
            result["modificationsCount"] = String(modificationsCount)
            result["loadsCount"] = String(loadsCount)
            return result
        }
    }
}
