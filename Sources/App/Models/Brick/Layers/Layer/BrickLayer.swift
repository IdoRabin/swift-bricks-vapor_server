//
//  BrickLayer.swift
//  Bricks
//
//  Created by Ido on 03/01/2022.
//

import Foundation
import AppKit
import Fluent
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("BrickLayer") 

final class BrickLayer : MNUIDable, CodableHashable, CustomStringConvertible {
    
    enum Selection : Int, Codable {
        case selected
        case nonselected
        
        var isSelected : Bool { return self == .selected }
    }
    
    enum Visiblity : Int, Codable {
        case hidden
        case visible
        
        var isHidden : Bool { return self == .hidden }
        var isVisible : Bool { return self != .hidden }
        
        var iconSymbolName : ImageString {
            switch self {
            case .visible:
                return ImageString("eye.fill")
            case .hidden:
                return ImageString("eye.slash.fill")
            }
        }
        
        func toggled()->Visiblity {
            switch self {
            case .visible: return .hidden
            case .hidden: return .visible
            }
        }
    }
    
    enum Access : Int, Codable {
        case locked
        case unlocked
        
        var isLocked : Bool { return self == .locked }
        var isUnlocked : Bool { return self != .locked }
        var iconSymbolName : ImageString {
            switch self {
            case .locked:
                return ImageString("lock.fill")
            case .unlocked:
                return ImageString("lock.open.fill")
            }
        }
        
        func toggled()->Access {
            switch self {
            case .locked: return .unlocked
            case .unlocked: return .locked
            }
        }
    }
    
    enum CodingKeys : String, CodingKey {
        case id = "id"
        case name = "name"
        case visiblity = "visiblity"
        case access = "access"
        case selection = "selection"
        case creationDate = "creationDate"
        case creatingUserId = "creatingUserId"
        
        var fieldKey : FieldKey {
            return .string(self.rawValue)
        }
    }
    
    // MARK: Public
    @Field(key: CodingKeys.name.fieldKey)
    var name : String? // Default = nil
    
    @Field(key: CodingKeys.visiblity.fieldKey)
    var visiblity : Visiblity // Default = .visible
    
    @Field(key: CodingKeys.access.fieldKey)
    var access : Access// Default = .unlocked
    
    @Field(key: CodingKeys.selection.fieldKey)
    var selection : Selection// Default = .nonselected
    
    // MARK: DemiPrivate
    @Field(key: CodingKeys.creationDate.fieldKey)
    private (set) var creationDate : Date? // Default = nil
    
    @Field(key: CodingKeys.creatingUserId.fieldKey)
    private (set) var creatingUserId : UserUID? // Default = nil
    
    // MARK: Identifiable / BUIDable / Vapor "Model" conformance
    @ID(key:.id) // @ID is a Vapor/Fluent ID wrapper for Model protocol, and Identifiable
    var id : UUID?
    var mnUID : MNUID? {
        guard let uid = self.id else {
            return nil
        }
        return LayerUID(uid: uid)
    }
    
    // MARK: Convenience var access - state booleans
    // Computed from other vars!
    var isSelected : Bool { return selection.isSelected}
    var isHidden : Bool { return visiblity.isHidden}
    var isVisible : Bool { return visiblity.isVisible}
    var isLocked : Bool { return access.isLocked}
    var isUnlocked : Bool { return access.isUnlocked}
    
    // Vapor Model requires implementing an empty init()
    init() {
        id = UUID()
        name = nil
        visiblity = .visible
        access = .unlocked
        selection = .nonselected
        creationDate = nil
        creatingUserId = nil
    }
    
    convenience init(uid:LayerUID? = nil, name newTitle:String? = nil) {
        self.init()
        id = uid?.uid ?? UUID()
        name = newTitle
    }
    
    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: Equatable
    static func == (lhs: BrickLayer, rhs: BrickLayer) -> Bool {
        return lhs.id == rhs.id
    }
    
    var description: String {
        var results = ["<BrickLayer id:\(self.mnUID.descOrNil)"]
        if let name = self.name, name.count > 0 {
            results.append("\"\(name)\"")
        }
        if self.isLocked {
            results.append("LCK")
        }
        if self.isHidden {
            results.append("HID")
        }
        if self.isSelected {
            results.append("SEL")
        }
        return results.joined(separator: String.NBSP) + ">"
    }
    
    func sanitize(_ str : String?)->String? {
        guard let uidStr = mnUID?.uuidString else {
            if Debug.IS_DEBUG {
                
            }
            return nil
        }
        
        var result = Brick.sanitize(str)
        
        if let str = str?.lowercased() {
            if str.contains(AppStr.UNNAMED.localized()) &&
                str.contains(uidStr.prefix(4).lowercased()){
                result = nil
            }
            
            if str.contains(uidStr.lowercased()) {
                result = nil
            }
        }
        
        return result
    }
    
}
