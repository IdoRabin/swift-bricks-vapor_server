//
//  PrefillAdminUserData.swift
//  
//
//  Created by Ido on 22/07/2023.
//

import Foundation
import Vapor
import FluentKit
import MNUtils
import MNVaporUtils
import DSLogger

fileprivate let dlog : DSLogger? = DconfigRateLimitMiddlewareLog.forClass("UserController + Prefill")?.setting(verbose: true)

fileprivate struct UserControllerPrefill : AppPermissionGiver {
    
}
extension UserController /* +Prefill */ {

    func prefillDebugUsersDataIfNeeded(db:Database) async throws {
        guard Debug.IS_DEBUG else {
            return
        }
        
        let prefiller = UserControllerPrefill()
        try await db.transaction { db in
            // Config contains the above info:
            let pii1 = MNPIIInfo(piiType: .name,
                                 strValue: "idorabin",
                                 domain: AppServer.DEFAULT_DOMAIN,
                                 hashedPwd: try UserPasswordAuthenticator.digestPwdPlainText(plainText: "123456"))
            
            let pii2 = MNPIIInfo(piiType: .email,
                                 strValue: "idorabin@gmail.com",
                                 domain: AppServer.DEFAULT_DOMAIN,
                                 hashedPwd: try UserPasswordAuthenticator.digestPwdPlainText(plainText: "123456"))
            
            guard try await self.dbFindUserLoginInfos(db: db, piiInfo: pii1, permissionGiver: globalAppServer!.defaultPersmissionGiver).count == 0 else {
                dlog?.fail("prefillDebugUsersDataIfNeeded user [idorabin] already exists. (pre-check)")
                return
            }
            
            var user : AppUser? = nil
            do {
                user = try await AppServer.shared.users?.dbCreateUser(
                    db:db,
                    displayName: "Ido Rabin",
                    piiInfo: pii1,
                    userSetup: { usr in
                        // Change any other prop for user before save
                        usr.status = .active
                    },
                    permissionGiver: prefiller)
                dlog?.verbose("prefillAdminUsersData idorabin DEBUG user was found or created: \(user.descOrNil)")
            } catch let error {
                let code = (error as? MNError)?.code ?? (error as NSError).code
                switch code {
                case AppErrorCode.db_already_exists.rawValue:
                    dlog?.fail("prefillDebugUsersDataIfNeeded DEBUG user [idorabin] already exists")
                case AppErrorCode.user_invalid_username.rawValue,
                    AppErrorCode.user_login_failed_user_name.rawValue,
                    AppErrorCode.user_login_failed_user_not_found.rawValue:
                    // User does not exist:
                    dlog?.fail("prefillDebugUsersDataIfNeeded DEBUG user [idorabin] does not exist:")
                default:
                    dlog?.verbose(log:.note,"prefillDebugUsersDataIfNeeded: error creating DEBUG user, code: \(code) error:\(String(reflecting: error))")
                }
            }
            
            if let user = user {
                _ = try await self.dbCreateUserLoginInfo(db: db, user: user, pii: pii2, permissionGiver: prefiller)
            }
        }
    }
    
    func prefillAdminUsersData(db:Database, user prefillUser:AppUser? = nil) async throws {
        guard Debug.IS_DEBUG else {
            return
        }
        
        dlog?.verbose("prefillAdminUsersData(app:user:\(prefillUser?.displayName ?? "<nil>" )")
        
        // MNUserPII
        let adminDomain         = AppServer.DEFAULT_DOMAIN
        let piiUserName         = AppServer.DEFAULT_ADMIN_IIP_USERNAME
        let piiUserPwdHashed    = try UserPasswordAuthenticator.digestPwdPlainText(plainText: AppServer.DEFAULT_ADMIN_IIP_PWD)
        let piiUserDisplayName  = AppServer.DEFAULT_ADMIN_DISPLAY_NAME
        
        // Config contains the above info:
        let pii = MNPIIInfo(piiType: .name,
                        strValue: piiUserName,
                        domain: adminDomain,
                        hashedPwd: piiUserPwdHashed)
        
        guard try await self.dbFindUserLoginInfos(db: db, piiInfo: pii, permissionGiver: globalAppServer!.defaultPersmissionGiver).count == 0 else {
            dlog?.fail("prefillAdminUsersData user [\(piiUserDisplayName)] already exists. (pre-check)")
            return
        }
        
        try await db.transaction { db in
            let prefiller = UserControllerPrefill()
            
            // Get or create user if needed
            
            // Get or create user info if needed
            var user : AppUser? = nil
            do {
                user = try await AppServer.shared.users?.dbCreateUser(
                    db:db,
                    displayName: prefillUser?.displayName ?? piiUserDisplayName,
                    piiInfo: prefillUser?.loginInfos.first?.userPII?.asPIIInfo(db:db) ?? pii,
                    userSetup: { usr in
                        // Change any other prop for user before save
                        usr.status = .active
                    },
                    permissionGiver: prefiller)
                
                dlog?.verbose("prefillAdminUsersData Admin user was found or created: \(user.descOrNil)")
            } catch let error {
                let code = (error as? MNError)?.code ?? (error as NSError).code
                
                switch code {
                case AppErrorCode.db_already_exists.rawValue:
                    dlog?.fail("prefillAdminUsersData user [\(piiUserDisplayName)] already exists")
                case AppErrorCode.user_invalid_username.rawValue,
                    AppErrorCode.user_login_failed_user_name.rawValue,
                    AppErrorCode.user_login_failed_user_not_found.rawValue:
                    // User does not exist:
                    dlog?.fail("prefillAdminUsersData user [\(piiUserDisplayName)] does not exist:")
                default:
                    dlog?.verbose(log:.note,"prefillAdminUsersData: error creating user, code: \(code) error:\(String(reflecting: error))")
                }
            }
        }
    }
    
}
