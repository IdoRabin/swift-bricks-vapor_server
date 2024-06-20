//
//  FluentLeafTableview+Types.swift
//
//
//  Created by Ido on 19/02/2024.
//

import Foundation
import MNUtils

public extension FluentLeafTableview {

    struct Config : JSONSerializable {
        let dbTableName : String
        
        // Operations allowed globally (forces .`select` into perRowOperations)
        let globalOperations : Operations
        
        // Operations allowed per-row
        let perRowOperations : Operations
        
        // Operations requiring user confirmation (alert), regardless of where they were taken (per-line, per-cell or global)
        let confirmOperations : Operations
        
        public static func `default`(dbTableName:String)-> Config {
            return Config(dbTableName: dbTableName,
                          globalOperations: [.delete],
                          perRowOperations: [.edit, .selectDeselect, .delete],
                          confirmOperations:[.delete])
        }
    }
}
