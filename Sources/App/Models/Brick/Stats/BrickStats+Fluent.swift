//
//  BrickStats+Fluent.swift
//  
//
//  Created by Ido on 22/07/2022.
//

import Foundation
import Fluent
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("BrickStats+Fluent")

extension BrickStats : Model {
    // Fluent Schema protocol: space, alias, schema
    // https://www.postgresql.org/docs/current/sql-keywords-appendix.html
    // See also in FluentModelEx.swift: "USER" / "user" is a postgres sql reserved work
} // inherits from Fields protocol

extension BrickStats : Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        
        return database.schema(BrickSettings.schema)
            .id() // primary key
            .field(CodingKeys.sessionCount.fieldKey,        .uint64,  .required)
            .field(CodingKeys.indexingCount.fieldKey,       .uint64,  .required)
            .field(CodingKeys.modificationsCount.fieldKey,  .uint64,  .required)
            .field(CodingKeys.savesCount.fieldKey,          .uint64,  .required)
            .field(CodingKeys.savesByCommandCount.fieldKey, .uint64,  .required)
            .field(CodingKeys.loadsCount.fieldKey,          .uint64,  .required)
            // TODO: .field(CodingKeys.loadsTimings.fieldKey,        .double,  .required)
            .unique(on: CodingKeys.id.fieldKey, name: "BrickStats unique by id")
            .ignoreExisting().create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Self.schema).delete()
    }
}
