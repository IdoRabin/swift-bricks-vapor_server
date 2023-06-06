//
//  File.swift
//  
//
//  Created by Ido on 16/12/2022.
//

import Foundation

#if VAPOR
import Fluent

/*
extension AppRole : Model {
    
    
    // Fluent Schema protocol: space, alias, schema
    // https://www.postgresql.org/docs/current/sql-keywords-appendix.html
    // See also in FluentModelEx.swift: "USER" / "user" is a postgres sql reserved work
} // inherits from Fields protocol

extension AppRole : Migration {
    
    // UNCOMMENT: 
//    func prepare(on database: Database) -> EventLoopFuture<Void> {
//        database.createOrGetEnumType(anEnumType: UsernameType.self).flatMap { usernameTypeEnum in
//            return database.schema(User.schema)
//                .id() // primary key
//                .field(CodingKeys.rabacName.fieldKey,   .string, .required)
//                .field(CodingKeys.title.fieldKey,       .string)
//                .field(CodingKeys.description.fieldKey, .string)
//
//                .field(CodingKeys.parent.fieldKey,    .custom(AppRole.self))
//                .field(CodingKeys.children.fieldKey,  .custom([AppRole].self), .required)
//
//                .field(CodingKeys.assignedUsers.fieldKey,    .custom([User].self))
//
//                .unique(on: CodingKeys.id.fieldKey, name: "AppRole unique by id")
//                .unique(on: CodingKeys.rabacName.fieldKey, name: "AppRole unique by rabacName")
//                .ignoreExisting().create()
//        }
//    }
//
//    func revert(on database: Database) -> EventLoopFuture<Void> {
//        // This table
//        return database.schema(Self.schema).delete()
//        //.flatMap {
//            // Destroy types blonging to this table
//        //}
//    }
}
 */
#endif

