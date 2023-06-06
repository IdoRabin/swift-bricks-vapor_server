//
//  AppRole.swift
//  
//
//  Created by Ido on 16/12/2022.
//

import Foundation
import DSLogger
import MNUtils

#if VAPOR
import Vapor
import Fluent
#else
public indirect enum FieldKey {
    case id
    case string(String)
    case aggregate
    case prefix(FieldKey, FieldKey)
}
#endif

fileprivate let dlog : DSLogger? = DLog.forClass("AppRole")

// Protocol
// MARK: AppRole final class
// TODO: check why final? does Vapor/Fluent require it be final?
/*final class AppRole : RabacRole {
    
    // MARK: Const
    // MARK: Static
    
    enum CodingKeys : String, CodingKey {
        // Basic
        case rabacName      = "rabacName"
        case id             = "id"
        case title          = "title"
        case description    = "deescription"
        
        case parent         = "parent"
        case children       = "children"
        
        case assignedUsers  = "assigned_users"
        
        #if VAPOR
        var fieldKey : FieldKey {
            return .string(self.rawValue)
        }
        #endif
    }
    
    // MARK: Properties / members
    @ID(key:.id) // @ID is a Vapor/Fluent ID wrapper for Model protocol, and Identifiable
    var id : UUID?
    
    @Field(key: CodingKeys.title.fieldKey)
    var title : String?
    
    @Field(key: CodingKeys.description.fieldKey)
    var description : String?
    
    @OptionalParent(key: CodingKeys.parent.fieldKey)
    var parent: AppRole?
    
    // Children<To>
    @Children(for: \.$parent)
    var children: [AppRole]
    
    // assigned Users
    @Field(key: CodingKeys.assignedUsers.fieldKey)
    var assignedUsers: [User]
    
    // MARK: Private
    var mnUID : RoleUID? {
        guard let uid = self.id else {
            return nil
        }
        return RoleUID(uid: uid)
    }
    
    // MARK: Lifecycle
    // Empty init required by Fields protocol
    static var _emptyInits = 0
    init() {
        Self._emptyInits += 1
        let newId = UUID()
        do {
            try super.init("ROL|\(Self._emptyInits)", isValidateNameUniqueness: false)
        } catch let error {
            let msg = "empty init crashed on exception" + Debug.StringOrEmpty("Error: \(String(describing:error))")
            dlog?.warning(msg)
            preconditionFailure(msg)
        }
        
        id = newId
        title = nil
        description = nil
        // DO NOT: parent = nil // Fluent makes parent a "read-only" property: do not assign manually!
        // children = []
        assignedUsers = []
    }
    
    convenience init(util:String) {
        do {
            try self.init("util_" + util, isValidateNameUniqueness: false)
        } catch {
            self.init()
        }
    }
    
    required init(_ newRabacName: String, isValidateNameUniqueness:Bool) throws {
        let newId = UUID()
        try super.init(newRabacName, isValidateNameUniqueness:isValidateNameUniqueness)
        id = newId
        title = newRabacName.snakeCaseToCamelCase()
            .replacingOccurrences(ofFromTo: [
                "_" : " "
            ])
        description = nil
        // DO NOT: parent = nil // Fluent makes parent a "read-only" property: do not assign manually!
        // children = []
        assignedUsers = []
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let rabacName = try container.decode(String.self, forKey:CodingKeys.rabacName)
        try super.init(rabacName, isValidateNameUniqueness: false)
        
        self.id = try container.decode(UUID.self, forKey:CodingKeys.id)
        self.rabacName = rabacName
        
        self.title = try container.decodeIfPresent(String.self, forKey:CodingKeys.title) ?? nil
        self.description = try container.decodeIfPresent(String.self, forKey:CodingKeys.description) ?? nil
        
        if let parentId = try container.decodeIfPresent(UUID.self, forKey:CodingKeys.parent) {
            dlog?.todo("Implement parentId \(parentId)  as parent")
            // case parent         = "parent"
            // DO NOT: self.parent = nil // Fluent makes parent a "read-only" property: do not assign manually!
        } else {
            // DO NOT: self.parent = nil // Fluent makes parent a "read-only" property: do not assign manually!
        }
        
        if let childrenIds = try container.decodeIfPresent([UUID].self, forKey:CodingKeys.children) {
            // case children       = "children"
            dlog?.todo("Implement childrenIds \(childrenIds.descriptionsJoined) as children")
            // self.children = []
        } else {
            // self.children = []
        }
        
        if let assignedUserIds = try container.decodeIfPresent([UUID].self, forKey:CodingKeys.assignedUsers) {
            // case assignedUsers  = "assigned_users"
            dlog?.todo("Implement assignedUserIds \(assignedUserIds.descriptionsJoined) as assignedUsers")
        } else {
            assignedUsers = []
        }
    }
    
    required init(stringAnyDict dict: StringAnyDictionary) throws {
        try super.init(stringAnyDict:dict)
    }
    
    // MARK: Public
    
}
*/
