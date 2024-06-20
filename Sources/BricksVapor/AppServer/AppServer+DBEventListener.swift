//
//  AppServer+DBEventListener.swift
//
//
//  Created by Ido Rabin for Bricks on 17/1/2024.
//

import Foundation
import Fluent
import MNUtils
import PostgresNIO

fileprivate let dlog : Logger? = Logger(label:"FluentDBEventsListener")// ?.setting(verbose: false)

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
            if let error = error as? PSQLError {
                dlog?.warning("FluentDBEventsListener --> dbDidMigrate for \(dbName) failed with PSQLError:\(error.fullDescription)")
            } else {
                dlog?.warning("FluentDBEventsListener --> dbDidMigrate for \(dbName) failed with error:\(error)")
            }
        } else {
            dlog?.verbose(symbol: .success, "FluentDBEventsListener --> dbDidMigrate \(dbName)")
        }
    }
    
}
