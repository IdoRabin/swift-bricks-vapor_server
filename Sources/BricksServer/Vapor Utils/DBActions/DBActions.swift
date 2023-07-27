//
//  DBInfos.swift
//  DBInfos
//
//  Created by Ido on 09/08/2022.
//

import Foundation
import Fluent
import FluentKit

protocol DBInfoProvider {
    func allTableNamesCompletion(db: Database, ignoreFluentTables : Bool, completion:@escaping (AppResult<[String]>)->Void)
    func allTableNamesAsync(db: Database, ignoreFluentTables : Bool) async ->AppResult<[String]>
}

protocol DBActionProvider {
    func dropAllTables(db: Database, ignoreFluentTables : Bool, completion:@escaping (AppResult<String>)->Void)
    func shutdown(db: Database)
}

/// Provides acces to DB-Wide actions such all "drop all tables" etc.
class DBActions {
    
    static let postgres = PostgresDBActions()
    // static sqLite ...
    // static mogodb..
}

