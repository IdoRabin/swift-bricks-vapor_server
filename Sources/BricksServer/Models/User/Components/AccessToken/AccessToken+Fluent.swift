//
//  AccessToken+Fluent.swift
//  
//
//  Created by Ido on 13/07/2022.
//

import Foundation
import Fluent
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("AccessToken+Fluent")

// MARK: Migration
extension AccessToken : Model {
    // static var schema: String is auto implemented in FluentModelEx.swift
    // Fluent Schema protocol: space, alias, schema
}

extension AccessToken : Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        
        return database.schema(AccessToken.schema)
            .id() // primary key
            .field(CodingKeys.expirationDate.fieldKey,     .datetime,   .required)
            .field(CodingKeys.lastUsedDate.fieldKey,       .datetime)
            .field(CodingKeys.user.fieldKey,               .uuid,       .required, .references(User.schema, User.CodingKeys.id.fieldKey))
                .ignoreExisting().create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Self.schema).delete()
    }
    
    func forceLoadUser(db:Database) async->User  {
        do {
            try await self.$user.load(on: db).get() // force-load user?
        } catch let error {
            dlog?.warning("accessToken - forced loading of user error: \(error.description)")
        }
        
        return self.$user.wrappedValue
    }
}
