//
//  UserPool.swift
//  
//
//  Created by Ido on 26/05/2023.
//

import Foundation
import DSLogger

#if VAPOR
import NIO
#endif

fileprivate let dlog : DSLogger? = DLog.forClass("UserPool")

protocol UserHTTPResponsable : Hashable ,Sendable {
    var code : Int { get }
    var reasonPhrase : String? { get }
}

protocol UserManager {
    /*
    // Vars
    var selfUser : User? { get set}
    
    // Funcs
    func getUsers(byIds uuids:[UUID])->AppResult<[User]>
    func getUser(byId uuid:UUID?)->AppResult<User>
    
    func getUsers(byUsernames usernames:[String])->AppResult<[User]>
    func getUser(byUsername username:String?)->AppResult<User>
    
    func update(users:[User])->AppResult<[UUID:any UserHTTPResponsable]>
     */
}

class UserPool {
    
}
