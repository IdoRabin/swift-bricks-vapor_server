//
//  BrickBasicInfo.swift
//  Bricks
//
//  Created by Ido Rabin on 11/06/2021.
//  Copyright © 2018 IdoRabin. All rights reserved.
//

import Foundation
import Fluent
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("BrickBasicInfo")

final class BrickBasicInfo : Codable, Hashable, MNUIDable {
    static let mnuidTypeStr: String = "BRK_INF"
    
    
    @Field(key: CodingKeys.creationDate.fieldKey)
    var creationDate:Date
    
//    @Field(key: CodingKeys.creatingUserId.fieldKey)
//    var creatingUserId:UUID? // = nil
//
//    @Field(key: CodingKeys.lastOpenedDate.fieldKey)
//    var lastOpenedDate:Date? // = nil
//
//    @Field(key: CodingKeys.lastClosedDate.fieldKey)
//    var lastClosedDate:Date? // = nil
//
//    @Field(key: CodingKeys.lastModifiedDate.fieldKey)
//    var lastModifiedDate:Date? // = nil
//
//    @Field(key: CodingKeys.lastSavedDate.fieldKey)
//    var lastSavedDate:Date? // = nil
//
//    @Field(key: CodingKeys.shouldRestoreOnInit.fieldKey)
//    var shouldRestoreOnInit:Bool // = false
    
//    @Enum(key: CodingKeys.templateType.fieldKey)
//    var templateType : BrickTemplateType // = .unknown
//
//    @Enum(key: CodingKeys.versionControlType.fieldKey)
//    var versionControlType : BrickVersionControlType // = .none
    
//    @Field(key: CodingKeys.projectVersionControlPath.fieldKey)
//    var projectVersionControlPath : URL? // = nil
    
    // Brick project files paths per user
//    @Field(key: CodingKeys.filePaths.fieldKey)
//    var filePaths : [MNUID:URL] // = [:] // owning user uuid : path for that user
//
//    // The project that the brick is pointing at:
//    @Field(key: CodingKeys.projectFolderPaths.fieldKey)
//    var projectFolderPaths : [MNUID:URL] // = // owning user uuid : path for that user
//
//    // The file paths inside the project that the brick is pointing at:
//    @Field(key: CodingKeys.projectFilePaths.fieldKey)
//    var projectFilePaths : [MNUID:URL] // = [:] // owning user uuid : path for that user
    
    private var _displayName : String? = nil
    
    enum CodingKeys : String, CodingKey, CaseIterable {
        case id                  = "id"
        case creationDate        = "creationDate"
        case creatingUserId      = "creatingUserId"
        case lastOpenedDate      = "lastOpenedDate"
        case lastClosedDate      = "lastClosedDate"
        case lastModifiedDate    = "lastModifiedDate"
        case lastSavedDate       = "lastSavedDate"
        case shouldRestoreOnInit = "shouldRestoreOnInit"
    
//        case templateType        = "templateType"
//        case versionControlType  = "versionControlType"
        
        case projectVersionControlPath = "projectVersionControlPath"
        case filePaths           = "filePaths"
        case projectFolderPaths  = "projectFolderPaths"
        case projectFilePaths    = "projectFilePaths"
        
        var fieldKey : FieldKey {
            return .string(self.rawValue)
        }
    }
    
    // MARK: Identifiable / MNUIDable / Vapor "Model" conformance
    @ID(key:.id) // @ID is a Vapor/Fluent ID wrapper for Model protocol, and Identifiable
    var id : UUID?
    
    public var displayName : String? {
        get {
            return self._displayName
        }
        set {
            let fileExtension = /*BrickDoc.extension() ??*/ AppConstants.BRICK_FILE_EXTENSION
            self._displayName = newValue?.trimmingSuffix("." + fileExtension)
        }
    }
    
    // Vapor Model requires implementing an empty init()
    init() {
        self.id = UUIDv5()
        self.creationDate = Date()
//        self.lastModifiedDate = nil
//        self.lastOpenedDate = nil
//        self.filePaths = [:]
//        self.projectFilePaths = [:]
//        self.projectFolderPaths = [:]
//        self.templateType = .unknown
    }
    
    // LosslessStringConvertivale requires this initializer
    init?(_ description: String) {
        
    }
    
    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: Equatable
    static func ==(lhs:BrickBasicInfo, rhs:BrickBasicInfo)->Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

// Sort by date in an array
extension Array where Element == BrickBasicInfo {
    func sortedByDate()->[BrickBasicInfo] {
        return self.sorted(by: { (infoA, infoB) -> Bool in
//            if let a = infoA.lastModifiedDate, let b = infoB.lastModifiedDate {
//                return a > b
//            }
//
//            if let a = infoA.lastClosedDate, let b = infoB.lastOpenedDate {
//                return a > b
//            }
//
//            if let a = infoA.lastOpenedDate, let b = infoB.lastOpenedDate {
//                return a > b
//            }
            
            return infoA.creationDate > infoB.creationDate
        })
    }
}

// Required by fluent for custom types
extension BrickBasicInfo : CustomDebugStringConvertible, LosslessStringConvertible {
    
    
    var description: String {
        var result = ""
        do {
            result = try AppJSONEncoder().encode(self).description
        } catch let error as NSError {
            dlog?.warning("description failed \(error.description)")
        }
        return result
    }
    
    var debugDescription: String {
        get {
            let formatter = DateFormatter.formatterByDateFormatString("dd/MM/yy HH:mm:ss.SSS")
            return "BrickBasicInfo \(displayName ?? "< untitled >" ) \(formatter.string(from: self.creationDate)) \(mnUID.descOrNil)"
        }
    }
}

// Sort by date in a dictionary
extension Dictionary where Value == BrickBasicInfo {
    func valuesSortedByDate()->[BrickBasicInfo] {
        return self.valuesArray.sortedByDate()
    }
}
