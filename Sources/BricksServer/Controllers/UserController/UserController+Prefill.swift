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

fileprivate let dlog : DSLogger? = DLog.forClass("UserController + Prefill")?.setting(verbose: true)

fileprivate struct UserControllerPrefill : AppPermissionGiver {
    
}
extension UserController /* +Prefill */ {

    func prefillAdminUsersData(db:Database, user prefillUser:AppUser? = nil) async throws {
        
        dlog?.verbose("prefillAdminUsersData(app:user:\(prefillUser?.displayName ?? "<nil>" )")
        
        // MNUserPIIConfig
        let adminDomain         = AppServer.DEFAULT_DOMAIN
        let piiUserName         = AppServer.DEFAULT_ADMIN_IIP_USERNAME
        let piiUserPwdHashed    = try UserPasswordAuthenticator.digestPwdPlainText(plainText: AppServer.DEFAULT_ADMIN_IIP_PWD)
        let piiUserDisplayName  = AppServer.DEFAULT_ADMIN_DISPLAY_NAME
        
        // Config contains the above info:
        let pii = MNPIIInfo(piiType: .name,
                        strValue: piiUserName,
                        domain: adminDomain,
                        hashedPwd: piiUserPwdHashed)
        
        try await db.transaction { db in
            let prefiller = UserControllerPrefill()
            
            // Get or create user if needed
            
            // Get or create user info if needed
            var user : AppUser? = nil
            do {
                user = try await AppServer.shared.users?.dbCreateUser(
                    db:db,
                    displayName: prefillUser?.displayName ?? piiUserDisplayName,
                    pii: prefillUser?.loginInfos.first?.userPII?.asPIIInfo(db:db) ?? pii,
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
                    dlog?.info("prefillAdminUsersData user [\(piiUserDisplayName)] already exists")
                case AppErrorCode.user_invalid_username.rawValue,
                    AppErrorCode.user_login_failed_user_name.rawValue,
                    AppErrorCode.user_login_failed_user_not_found.rawValue:
                    // User does not exist:
                    dlog?.info("prefillAdminUsersData user [\(piiUserDisplayName)] does not exist:")
                default:
                    dlog?.verbose(log:.note,"prefillAdminUsersData: error creating user, code: \(code) error:\(String(reflecting: error))")
                }
            }
        }
    }
    
}
