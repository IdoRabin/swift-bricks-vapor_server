//
//  BServerUIDs.swift
//  BServer
//
//  Created by Ido on 06/04/2022.
//

import Foundation
import MNUtils
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("BServerUIDs")

class LayerUID : MNUID {
    override var type : String { return MNUIDTypes.layer.rawValue }
    override func setType(str:String? = MNUIDTypes.layer.rawValue) {/* does nothing ; */}
}

class PersonUID : MNUID {
    override var type : String { return MNUIDTypes.person.rawValue }
    override func setType(str:String? = MNUIDTypes.person.rawValue) {/* does nothing ; */}
}

class BrickDocUID : MNUID {
    override var type : String { return MNUIDTypes.doc.rawValue }
    override func setType(str:String? = MNUIDTypes.doc.rawValue) {/* does nothing ; */}
}

class CompanyUID : MNUID {
    override var type : String { return MNUIDTypes.company.rawValue }
    override func setType(str:String? = MNUIDTypes.company.rawValue) {/* does nothing ; */}
}

class UserUID : MNUID {
    override var type : String { return MNUIDTypes.user.rawValue }
    override func setType(str:String? = MNUIDTypes.user.rawValue) {/* does nothing ; */}
}

class RoleUID : MNUID {
    override var type : String { return MNUIDTypes.role.rawValue }
    override func setType(str:String? = MNUIDTypes.role.rawValue) {/* does nothing ; */}
}
