//
//  Brick+Fluent.swift
//  
//
//  Created by Ido on 13/07/2022.
//

import Foundation
import Fluent

// MARK: Fluent
extension Brick : Model {
    // static var schema: String is auto implemented in FluentModelEx.swift
    // Fluent Schema protocol: space, alias, schema
}

extension Brick : Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Brick.schema)
            .id() // primary key
//          TODO:  .field(CodingKeys.info.fieldKey,        .custom(BrickBasicInfo.self),  .required)
//          TODO:  .field(CodingKeys.settings.fieldKey,    .custom(BrickSettings.self),   .required)
//          TODO:  .field(CodingKeys.stats.fieldKey,       .custom(BrickStats.self),      .required)
//          TODO:  .field(CodingKeys.layers.fieldKey,      .custom(BrickLayers.self),     .required)
            .unique(on: CodingKeys.id.fieldKey, name: "Brick unique by id")
            .ignoreExisting().create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Self.schema).delete()
    }
}

