//
//  UserController+DB.swift
//  
//
//  Created by Ido on 20/07/2023.
//

import Foundation
import Fluent
import MNUtils
import MNVaporUtils
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("UserController")?.setting(verbose: true)

extension UserController /* DB */ {
    // MARK: Users pii table
    
    // MARK: Users login info table
    func dbFindUserLogins(db:Database, pii:MNPII, acceptedPIITypes : [MNUserPIIType] = MNUserPIIType.allCases, permissionGiver:AppPermissionGiver) async throws -> [MNUserLoginInfo] {
        
        // TODO: Use Join
        
        // Find piis
        let userPIIs = try await MNUserPII.query(on: db)
            .filter(\.$piiString ~~ pii.strValue)
            .filter(\.$piiDomain ~~ pii.domain)
            // is this required? .filter(\.$piiType == piiConfig.piiType) ??
            .filter(\.$piiType ~~ /* in */ acceptedPIITypes)
            .with(\.$loginInfo) // load loginInfo parent
            .top(20) // for mem safety JIC
        
        guard userPIIs.count > 0 else {
            dlog?.verbose(log:.fail, "dbFindUserLogin failed finding username pii value: [\(pii.strValue)] at domain: [\(pii.domain)]")
            return []
            // DO NOT: throw MNError(code: .user_login_failed_user_name, reason: "User does not exist or blocked.")
        }
        guard userPIIs.count > 1 else {
            dlog?.warning("dbFindUserLogin located \(userPIIs.count) Piis with the same piiString, piiDomain, and piiType!")
            throw MNError(code: .user_login_failed, reason: "Multiple users with same pii signature (user name, domain and type)")
        }
        
        // dlog?.info(">> \(piis.count) piis: \(piis)")
        let loginInfos = userPIIs.compactMap({ userPII in
            if (userPII.loginInfo.loginPasswordHashed == pii.hashedPwd) {
                return userPII.loginInfo
            }
            return nil // compactMap
        })
        
        // JIC
        guard userPIIs.count == loginInfos.count else {
            throw MNError(code: .user_login_failed_password, reason: "User login infos needs decoupling. Requires support.")
        }
        
        return loginInfos
    }
    
    func dbFindUserLogins(db:Database, domain:String, accessToken:String, permissionGiver:AppPermissionGiver) async throws -> MNUserLoginInfo {
        // DECODE BEARER TOKEN?
        // Get userId in token
        // find user/s for id
        throw MNError(code: .db_failed_init, reason: "Failed dbFindUserLogins(accessToken). TODO: Implement")
    }
    
    // MARK: Users table
    // Create
    private func dbCreatePersonInfo(db:Database, user:MNUser, displayName:String?, permissionGiver:AppPermissionGiver) async throws -> MNPersonInfo {
        
        let aPersonInfo = MNPersonInfo(id: user.id!,
                                       parent: user,
                                       name: displayName ?? user.displayName,
                                       personaType: .person,
                                       language: MNLanguage.default)
        return aPersonInfo
    }
    
    private func dbCreateUserLoginInfo(db:Database, user:MNUser, pii:MNPII, permissionGiver:AppPermissionGiver) async throws -> MNUserLoginInfo {
        
        let aLoginInfo = MNUserLoginInfo(user: user,
                                         pii: pii)
        var infos = user.$loginInfos.value ?? []
        if !infos.compactMap({ $0.id }).contains(aLoginInfo.id) {
            // Only infos with an id:
            infos.append(aLoginInfo)
            user.$loginInfos.value = infos
        }
        
        return aLoginInfo
    }
    
    func dbCreateUser(db:Database, displayName:String, pii:MNPII, personInfo:MNPersonInfo? = nil, permissionGiver:AppPermissionGiver) async throws -> AppUser {
        // NOTE: piiString is usually a username in its various types (email, name, personnel number etc)
        var newUser : MNUser? = nil
        var permission : MNPermission<String, MNError> = .allowed("dbCreateUser")
        
        // TODO: permissionGiver....
        try permission.throwIfForbidden()
        
        // Only one user login found:
        let loginInfos = try await dbFindUserLogins(db: db, pii: pii, permissionGiver: permissionGiver)
        switch loginInfos.count {
        case 0:
            permission = .allowed("dbCreateUser")
        case 1:
            permission = .forbidden(MNError(code: .user_invalid_username, reason: "A user with this \(pii.piiType.displayName) already exists."))
        default:
            permission = .forbidden(MNError(code: .user_login_failed_user_not_found, reason: "User login credentials require review. Support is required."))
        }
        try permission.throwIfForbidden()
        
        do {
            newUser = try MNUser(displayName: displayName, pii: pii)
            try await db.transaction {[self, newUser] db in
                try await newUser!.save(on: db)
                
                let aLoginInfo = try await dbCreateUserLoginInfo(db: db, user: newUser!, pii: pii, permissionGiver: permissionGiver)
                try await aLoginInfo.save(on: db)
                
                let loginInfoChildren = aLoginInfo.createChildren(user: newUser!, pii: pii)
                try await loginInfoChildren.loginPii?.save(on: db)
                try await loginInfoChildren.accessToken?.save(on: db)
                
                let cascaded = aLoginInfo.getItemsCascade(db:db)
                dlog?.info(" >>== cascaded:\n\(cascaded.descriptionLines)")
                
                // let aUserPII = aLoginInfo.$loginPII.wrappedValue!
                // let aUserAccessToken = aLoginInfo.$accessToken.wrappedValue!
                
                // Person Info:
                var aPersonInfo = personInfo
                if aPersonInfo == nil {
                    aPersonInfo = try await dbCreatePersonInfo(db: db, user: newUser!, displayName: displayName, permissionGiver: permissionGiver)
                } else {
                    aPersonInfo!.$user.id = newUser!.id
                }
                try await aPersonInfo!.save(on: db)
            }
        } catch let error {
            dlog?.verbose(log:.warning, "dbCreateUser: Failed creating user: underlyingError: \(String(reflecting: error))")
            throw MNError(code:.db_failed_creating, reason: "Failed creating user", underlyingError: error)
        }
        
        return newUser!
    }
    
    // Read
    func dbGetFullUserInfo(db:Database, userId:UUIDv5, permissionGiver:AppPermissionGiver) async throws -> MNPersonInfo {
        throw MNError(code: .db_failed_init, reason: "dbGetFullUserInfo Failed. TODO: Implement")
    }
    
    func dbFindUsers(db:Database, pii:MNPII, permissionGiver:AppPermissionGiver) async throws -> [AppUser] {
        let infos = try await self.dbFindUserLogins(db: db, pii: pii, permissionGiver: permissionGiver)
        let users = infos.compactMap { $0.user }
        for user in users {
            dlog?.info(">>>> Found user: \(user.description)")
        }
        
        /* // TODO: Load users manually
        if users.count < infos.count {
            dlog?.note("dbFindUsers: Not all users were loaded")
            let ids = Set(infos.compactMap { $0.user?.id })
            if ids.count > 0 {
                users = []
                // TODO: Load all users for the given id:
                // https://docs.vapor.codes/fluent/query/#subset-filter
                //  let queriedUsers = MNUser.query(on: db)
                //      ..filter(\.$type ~~ [.gasGiant, .smallRocky]) ???
            }
        } */
        
        guard users.count > 0 else {
            dlog?.warning("TODO: Implement dbFindUsers last part!")
            throw MNError(code:.user_login_failed_user_not_found, reason: "dbFindUser: 0 users found for pii")
        }
        
        throw MNError(code: .db_failed_init, reason: "Failed dbFindUsers(piiValue:piiHashedPwd). TODO: Implement")
    }
    
    func dbFindUsers(db:Database, domain:String, accessToken:String, permissionGiver:AppPermissionGiver) async throws -> [AppUser] {
        let userLogin = try await self.dbFindUserLogins(db: db, domain:domain, accessToken: accessToken, permissionGiver: permissionGiver)
        throw MNError(code: .db_failed_init, reason: "Failed dbFindUsers(accessToken:..) TODO: Implement")
    }
    
    // Update
    func dbUpdateUsers(infos:[UUID:MNPersonInfo], permissionGiver:AppPermissionGiver) async throws -> [MNUID] {
        throw MNError(code: .db_failed_init, reason: "Failed dbUpdateUsers(infos[:]). TODO: Implement")
    }
    
    // Delete
    func dbDeleteUsers(ids:[UUID], permissionGiver:AppPermissionGiver) async throws ->AppResult<[MNUID]> {
        throw MNError(code: .db_failed_init, reason: "Failed dbDeleteUsers(ids:). TODO: Implement")
    }
}
