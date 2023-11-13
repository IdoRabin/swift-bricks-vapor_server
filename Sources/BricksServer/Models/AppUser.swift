//
//  AppUser.swift
//  
//
//  Created by Ido on 20/07/2023.
//

import Foundation
import Vapor
import MNVaporUtils // defines MNUser

// aliased MNUser
// MNUser+Vapor.swift requires @unchecked Sendable & Authenticatable by 
extension AppUser : @unchecked Sendable { // , Authenticatable
    // TODO: either implement as really sendable or find a way to circumvent this
}

extension AppUser : AppPermissionGiver {
    // TODO: implement
}
