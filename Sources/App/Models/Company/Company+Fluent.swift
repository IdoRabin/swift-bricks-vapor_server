//
//  Company+Fluent.swift
//  
//
//  Created by Ido on 13/07/2022.
//

import Foundation
import Fluent

// MARK: Fluent
extension Company : Model {
    // static var schema: String is auto implemented in FluentModelEx.swift
    // Fluent Schema protocol: space, alias, schema
}

extension Company : Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Company.schema)
            .id() // primary key
            .field(CodingKeys.name.fieldKey, .array(of: .string),  .required)
            .field(CodingKeys.tags.fieldKey, .array(of: .string), .required)
            .ignoreExisting().create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Self.schema).delete()
    }
}

