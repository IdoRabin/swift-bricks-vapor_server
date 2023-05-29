//
//  File.swift
//  
//
//  Created by Ido on 13/07/2022.
//

import Foundation
import Fluent

// MARK: Fluent
extension Person : Model {
    // static var schema: String is auto implemented in FluentModelEx.swift
    // Fluent Schema protocol: space, alias, schema
}

extension Person : Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Person.schema)
            .id() // primary key
            .field(CodingKeys.name.fieldKey,       .array(of: .string),   .required)
            .field(CodingKeys.company.fieldKey,    .string)
            .field(CodingKeys.idinorg.fieldKey,    .string,               .required)
            .field(CodingKeys.phoneNrs.fieldKey,   .string)
            .field(CodingKeys.emails.fieldKey,     .array(of: .string))
            .field(CodingKeys.socials.fieldKey,    .dictionary(of: .string))
            .field(CodingKeys.bDay.fieldKey,       .datetime)
            .field(CodingKeys.eDay.fieldKey,       .datetime)
            .field(CodingKeys.rank.fieldKey,       .string)
            .field(CodingKeys.tags.fieldKey,       .array(of: .string),   .required)
            .field(CodingKeys.createdAt.fieldKey,  .datetime,             .required)
            .field(CodingKeys.updatedAt.fieldKey,  .datetime)
            .field(CodingKeys.deletedAt.fieldKey,  .datetime)
            .ignoreExisting().create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Self.schema).delete()
    }
}
