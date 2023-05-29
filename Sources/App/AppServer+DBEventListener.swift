//
//  File.swift
//  
//
//  Created by Ido on 08/02/2023.
//

import Foundation
import Fluent
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("FluentDBEventsListener")?.setting(verbose: false)

protocol FluentDBEventsListener {
    func dbWillInit(_ strContext:String)
    func dbDidInit(db:Database)
    func dbWillMigrate(db:Database)
    func dbDidMigrate(db:Database, error:Error?)
}

extension AppServer : FluentDBEventsListener {
    
    func dbWillInit(_ strContext:String) {
        dlog?.verbose("FluentDBEventsListener --> dbWillInit \(strContext)")
    }
    func dbDidInit(db:Database) {
        dlog?.verbose("FluentDBEventsListener --> dbDidInit \(dbName)")
    }
    func dbWillMigrate(db:Database) {
        dlog?.verbose("FluentDBEventsListener --> dbWillMigrate \(dbName)")
    }
    func dbDidMigrate(db:Database, error:Error?) {
        if let error = error {
            dlog?.warning("FluentDBEventsListener --> dbDidMigrate for \(dbName) failed with error:\(error)")
        } else {
            dlog?.verbose(log: .success, "FluentDBEventsListener --> dbDidMigrate \(dbName)")
        }
    }
    
}
