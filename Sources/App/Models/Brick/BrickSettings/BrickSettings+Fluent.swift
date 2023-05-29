//
//  File.swift
//  
//
//  Created by Ido on 14/07/2022.
//

import Foundation
import Fluent

extension BrickSettings : Model {
    // static var schema: String is auto implemented in FluentModelEx.swift
    // Fluent Schema protocol: space, alias, schema
} // inherits from Fields protocol

// MARK: Migration BrickSettings
extension BrickSettings : Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        
        return database.schema(BrickSettings.schema)
            .id() // primary key
            .field(CodingKeys.drawingSnapToGrid.fieldKey,   .bool,  .required)
            .field(CodingKeys.drawingGridSize.fieldKey,     .double, .required)
            .unique(on: CodingKeys.id.fieldKey, name: "BrickSettings unique by id")
            .ignoreExisting().create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Self.schema).delete()
    }
}
