//
//  User+Roles.swift
//  
//
//  Created by Ido on 26/05/2023.
//

import Foundation


// TODO: reimplement
extension User {
//    @Field(key: CodingKeys.roles.fieldKey)
//    var roleIds : [RoleUID] {
//        didSet {
//            // Save to cahce:
//            if User.cahcesFetchedRoles {
//                // This will trigger the cahing mechanism
//                _ = self.roles
//            }
//        }
//    }
//
//    // RabacPerson required roles.
//    private var _lastRolesFetchedHash : Int = 0
//    private var _lastRolesFetched : [Weak<AppRole>] = []
//    var rabacRoles : [RabacRole] {
//        return self.roles
//    }
//
//    var roles : [AppRole] {
//
//        // Return cahced value is needed:
//        if User.cahcesFetchedRoles &&
//            self._lastRolesFetched.invalidate() == false {
//
//            // Calc hash value:
//            let hash = self.roleIds.hashValue
//            if _lastRolesFetchedHash == hash {
//                return _lastRolesFetched.wrappedValues()
//            }
//        }
//
//        // Fetch roles
//        // TODO: Load from DB? From where we want...
//        let fethcedRoles : [AppRole] = [] // Rabac.shared...
//        if fethcedRoles.count > 0 {
//
//            // Save to cache
//            if User.cahcesFetchedRoles {
//                self.roleIds = fethcedRoles.compactMap { $0.buid }
//                self._lastRolesFetchedHash = self.roleIds.hashValue
//                self._lastRolesFetched = Weak.newWeakArray(from: fethcedRoles)
//            }
//        } else {
//            dlog?.warning("Fetched 0 roles for roleIds: \(self.roleIds.descriptionsJoined)")
//        }
//
//        return fethcedRoles
//    }
}
