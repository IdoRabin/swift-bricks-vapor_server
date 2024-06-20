//
//  User+Authenticatable.swift
//
//
//  Created by Ido on 18/01/2024.
//

import Foundation
import Vapor
import Fluent

// BASIC AUTH:
/*
    // To get a token:
     curl --request GET/POST \
         --url "https://..../some_func" \
         --header "Authorization: Bearer YOUR-TOKEN" \
         --header "X-GitHub-Api-Version: 2022-11-28"
 
    // When token available:
    curl --request GET/POST \
    --url "https://..../some_func" \
    --header "Authorization: Bearer YOUR-TOKEN" \
    --header "X-GitHub-Api-Version: 2022-11-28"
*/

extension User : SessionAuthenticatable {
    
    var sessionID: UUID {
        return self.id!
    }
    
    typealias SessionID = UUID

}

extension User: ModelAuthenticatable {
  static let usernameKey = \User.$username
  static let passwordHashKey = \User.$passwordHash
  
  func verify(password: String) throws -> Bool {
    try Bcrypt.verify(password, created: self.passwordHash)
  }
}
