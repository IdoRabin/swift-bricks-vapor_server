//
//  User+Fluent.swift
//  
//
//  Created by Ido on 13/07/2022.
//

import Foundation

#if VAPOR || FLUENT
import DSLogger
import Fluent
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("User+Fluent")
/*
extension User : Model {
    // Fluent Schema protocol: space, alias, schema
    // https://www.postgresql.org/docs/current/sql-keywords-appendix.html
    // See also in FluentModelEx.swift: "USER" / "user" is a postgres sql reserved work
} // inherits from Fields protocol

// MARK: Migration User
extension User : Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        
        // public func createOrGetEnumType<T:AppModelStrEnum>(anEnumType:T.Type)->EventLoopFuture<DatabaseSchema.DataType> ---
        
        database.createOrGetEnumType(anEnumType: UsernameType.self).flatMap { usernameTypeEnum in
            return database.schema(User.schema)
                .id() // primary key
                .field(CodingKeys.person.fieldKey,                .uuid)
                .field(CodingKeys.passwordHash.fieldKey,          .string,                    .required)
                .field(CodingKeys.createdAt.fieldKey,             .datetime,                  .required)
                .field(CodingKeys.updatedAt.fieldKey,             .datetime)
                .field(CodingKeys.deletedAt.fieldKey,             .datetime)
            
                .field(CodingKeys.username.fieldKey,              .string,                    .required)
                .field(CodingKeys.userDomain.fieldKey,            .string,                    .required)
                .field(CodingKeys.usernameType.fieldKey,        usernameTypeEnum,             .required,   .custom("DEFAULT '\(UsernameType.unknown.rawValue)'"))
            
                .unique(on: CodingKeys.id.fieldKey, name: "User unique by id")
                .unique(on: CodingKeys.username.fieldKey, name: "User unique by username")
                .ignoreExisting().create()
        }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        // This table
        return database.schema(Self.schema).delete().flatMap {
            // Its constructing types
            return database.enum(UsernameType.dbTypeName).delete()
        }
    }
}
 */
#endif

