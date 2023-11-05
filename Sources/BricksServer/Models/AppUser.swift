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
extension AppUser  : @unchecked Sendable { // , Authenticatable
    
}
