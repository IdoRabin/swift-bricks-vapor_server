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
    func dbFindUserLoginInfos(db:Database, piiInfo:MNPIIInfo, acceptedPIITypes : [MNUserPIIType] = MNUserPIIType.allCases, permissionGiver:AppPermissionGiver) async throws -> [MNUserLoginInfo] {
        
        // TODO: Use Join
        
        // Find piis
        // Personal Identification Information for a user: the info needed to login (username, hashed password)
        let userPIIs = try await MNUserPII.query(on: db)
            .filter(\.$piiString, .caseInsensitve, piiInfo.strValue)
            .filter(\.$piiDomain, .caseInsensitve, piiInfo.domain)
            // TODO: is this required? .filter(\.$piiType == piiConfig.piiType) ??
            .filter(\.$piiType ~~ /* in */ acceptedPIITypes)
            .with(\.$loginInfo) // load loginInfo parent
            .top(50) // for mem safety JIC
        
        guard userPIIs.count > 0 else {
            dlog?.verbose(log:.fail, "dbFindUserLoginInfos failed finding username pii value: [\(piiInfo.strValue)] at domain: [\(piiInfo.domain)]")
            return []
            // DO NOT: throw MNError(code: .user_login_failed_user_name, reason: "User does not exist or blocked.")
        }
        
        // IF we find an existing pii, we expect it to appear only once. More than that means there is a serious uniqueing problem in the table.
        guard userPIIs.count == 1 else {
            dlog?.warning("dbFindUserLogin located \(userPIIs.count) Piis with the same piiString, piiDomain, and piiType!")
            throw MNError(code: .user_login_failed, reason: "Multiple users with same pii signature (user name, domain and type)")
        }
        
        // dlog?.info(">> \(piis.count) piis: \(piis)")
        let loginInfos = userPIIs.compactMap({ userPII in
            if (userPII.loginInfo.user?.id == userPII.userId) {
                return userPII.loginInfo
            }
            return nil // compactMap
        })
        
        // JIC
        guard userPIIs.count == loginInfos.count else {
            throw MNError(code: .user_login_failed_password, reason: "User login infos has some dicreprencies. Please request support.")
        }
        
        return loginInfos
    }
    
    func dbFindUserLogins(db:Database, domain:String, accessToken:String, permissionGiver:AppPermissionGiver) async throws -> [MNUserLoginInfo] {
        // Get userId by accessToken
        
        // find user for id
        
        // get login infos for this user
        
        throw MNError(code: .db_failed_init, reason: "Failed dbFindUserLoginInfos(accessToken). TODO: Implement")
    }
    
    // MARK: Users table
    // Create
    private func dbCreatePersonInfo(db:Database, user:AppUser, displayName:String?, permissionGiver:AppPermissionGiver) async throws -> MNPersonInfo {
        
        let aPersonInfo = MNPersonInfo(id: user.id!,
                                       parent: user,
                                       name: displayName ?? user.displayName,
                                       personaType: .person,
                                       language: MNLanguage.default)
        try await aPersonInfo.create(on: db)
        return aPersonInfo
    }
    
    func dbCreateUserLoginInfo(db:Database, user:AppUser, pii:MNPIIInfo, permissionGiver:AppPermissionGiver) async throws -> MNUserLoginInfo {
        
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
    
    func dbCreateUser(db:Database, displayName:String, piiInfo:MNPIIInfo, personInfo:MNPersonInfo? = nil, userSetup:((AppUser) -> Void)? = nil, permissionGiver:AppPermissionGiver) async throws -> AppUser {
        // NOTE: piiString is usually a username in its various types (email, name, personnel number etc)
        var newUser : AppUser? = nil
        var permission : MNPermission<String, MNError> = .allowed("dbCreateUser")
        
        // TODO: permissionGiver....
        try permission.throwIfForbidden()
        
        // Only one user login found:
        let loginInfos = try await dbFindUserLoginInfos(db: db, piiInfo: piiInfo, permissionGiver: permissionGiver)
        switch loginInfos.count {
        case 0:
            permission = .allowed("dbCreateUser")
        case 1:
            permission = .forbidden(MNError(code: .db_already_exists, reason: "A user with this \(piiInfo.piiType.displayName) already exists."))
        default:
            permission = .forbidden(MNError(code: .db_failed_creating, reason: "User login credentials require review. Support is required."))
        }
        try permission.throwIfForbidden()
        
        do {
            newUser = try AppUser(displayName: displayName, pii: piiInfo, setup: userSetup)
            try await db.transaction {[self, newUser] db in
                try await newUser!.save(on: db)
                
                let aLoginInfo = try await dbCreateUserLoginInfo(db: db, user: newUser!, pii: piiInfo, permissionGiver: permissionGiver)
                let loginInfoChildren = aLoginInfo.createChildren(user: newUser!, pii: piiInfo)
                
                // NOTE: Order of save matters:
                try await aLoginInfo.save(on: db)
                try await loginInfoChildren.userPii?.save(on: db)
                try await loginInfoChildren.accessToken?.save(on: db)
                
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
    // [1]
    func dbGetUserPersonInfo(db:Database, userId:UUIDv5, permissionGiver:AppPermissionGiver) async throws -> MNPersonInfo {
        throw MNError(code: .db_failed_init, reason: "dbGetUserPersonInfo Failed. TODO: Implement")
    }
    
    func dbFindUsers(db:Database, ids: [UUID], permissionGiver:AppPermissionGiver) async throws -> [AppUser]  {
        guard ids.count > 0 else {
            return []
        }
        
        return try await AppUser.query(on: db).filter(\.$id ~~ ids).top(ids.count)
    }
    
    func dbFindUsers(db:Database, piiInfo:MNPIIInfo, permissionGiver:AppPermissionGiver) async throws -> [AppUser] {
        
        // Find user login infos:
        let infos = try await self.dbFindUserLoginInfos(db: db, piiInfo: piiInfo, permissionGiver: permissionGiver)
        
        // Force load users from their table from the infos (if needed)
        let userIds = infos.compactMap { $0.$user.id } // TODO: Why usera are not loaded with the dollar sign?
        let result = try await self.dbFindUsers(db: db, ids: userIds, permissionGiver: permissionGiver)
        dlog?.verbose("dbFindUsers found \(result.count) users.")
        
        guard result.count > 0 else {
            dlog?.note("0 Users found for PII:\(piiInfo.description)")
            throw AppError(code:.user_login_failed_user_not_found, reason: "dbFindUser: 0 users found for person identifying info.")
        }
        
        return result
    }
    
    func dbFindUsers(db:Database, domain:String, accessToken:String, permissionGiver:AppPermissionGiver) async throws -> ([AppUser]) {
        let userLoginInfos = try await self.dbFindUserLogins(db: db, domain:domain, accessToken: accessToken, permissionGiver: permissionGiver)
        
        // TODO: Force-load users manually if needed
        
        for loginInfo in userLoginInfos {
            if loginInfo.$user.id == nil {
                let msg = "Failed dbFindUsers(accessToken:..) login info does not point to a user."
                throw MNError(code: .db_failed_query, reason: msg)
            }
        }
        
        return userLoginInfos.compactMap { $0.user }
    }
    
    // Update
    func dbUpdateUsers(infos:[UUID:MNPersonInfo], permissionGiver:AppPermissionGiver) async throws -> [MNUID] {
        // let users =
        throw MNError(code: .db_failed_init, reason: "Failed dbUpdateUsers(infos[:]). TODO: Implement")
    }
    
    // Delete
    func dbDeleteUsers(ids:[UUID], permissionGiver:AppPermissionGiver) async throws ->AppResult<[MNUID]> {
        throw MNError(code: .db_failed_init, reason: "Failed dbDeleteUsers(ids:). TODO: Implement")
    }
}
