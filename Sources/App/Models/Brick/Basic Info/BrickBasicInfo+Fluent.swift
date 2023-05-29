//
//  File.swift
//  
//
//  Created by Ido on 14/07/2022.
//

import Foundation
import Fluent
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("BrickBasicInfo+Fluent")

// Extensions requiring no implementations
extension BrickBasicInfo : Model {
    // static var schema: String is auto implemented in FluentModelEx.swift
    // Fluent Schema protocol: space, alias, schema
} // inherits from Fields protocol

extension BrickBasicInfo : Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        
        return database.createOrGetEnumType(anEnumType: BrickVersionControlType.self).flatMap { appRoleTypeEnum in
            database.createOrGetEnumType(anEnumType: BrickTemplateType.self).flatMap { appRoleTypeEnum in
                return database.schema(BrickBasicInfo.schema)
                    .id() // primary key
                    .field(CodingKeys.creationDate.fieldKey,        .datetime, .required)
                    .field(CodingKeys.creatingUserId.fieldKey,      .uuid)
                    .field(CodingKeys.lastOpenedDate.fieldKey,      .datetime)
                    .field(CodingKeys.lastClosedDate.fieldKey,      .datetime)
                    .field(CodingKeys.lastModifiedDate.fieldKey,    .datetime)
                    .field(CodingKeys.lastSavedDate.fieldKey,       .datetime)
                    .field(CodingKeys.shouldRestoreOnInit.fieldKey, .bool)
                // TODO: .field(CodingKeys.templateType.fieldKey,        templateEnum)
                // TODO: .field(CodingKeys.versionControlType.fieldKey,  versionControlEnum)
                // TODO: .field(CodingKeys.projectVersionControlPath.fieldKey, .string)
                // TODO: .field(CodingKeys.filePaths.fieldKey,           .dictionary(of: .string))
                // TODO: .field(CodingKeys.projectFolderPaths.fieldKey,  .dictionary(of: .string))
                // TODO: .field(CodingKeys.projectFilePaths.fieldKey,    .dictionary(of: .string))
                    .unique(on: CodingKeys.id.fieldKey, name: "BrickBasicInfo unique by id")
                    .ignoreExisting().create()
            }
        }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Self.schema).delete().flatMap {
            database.enum(BrickTemplateType.dbTypeName).delete().flatMap {
                return database.enum(BrickVersionControlType.dbTypeName).delete()
            }
        }
    }
}

