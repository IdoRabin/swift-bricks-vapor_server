//
//  AppPrefillData.swift
//  
//
//  Created by Ido on 16/07/2023.
//

import Foundation
import Vapor
import FluentKit
import DSLogger

import MNVaporUtils // contains some needed fluent models
import RRabac       // contains some needed fluent models

fileprivate let dlog : DSLogger? = DLog.forClass("App")?.setting(verbose: true)

class AppPrefillData {
    
    // MARK: Properties
    @AppSettable(name: "AppPrefillData.wasPrefilled", default: false) static var wasPrefilled : Bool
    
    // MARK: Private
    private func prefillRRabacDataIfNeeded(app:AppServer, db:Database) async throws {
        guard let rrabac = app.vaporApplication?.middleware.getMiddleware(ofType: RRabacMiddleware.self) else {
            dlog?.note("prefillRRabacDataIfNeeded failed finding RRabacMiddleware instance in app.")
            return
        }
        
        dlog?.verbose("prefillRRabacDataIfNeeded \(rrabac)")
    }
    
    public func prefillUserDataIfNeeded(app:AppServer, db:Database) async throws {
        dlog?.verbose("prefillUserDataIfNeeded. Default domain: \(AppServer.DEFAULT_DOMAIN)")
        let RESET_LOGIN_INFO = Debug.IS_DEBUG && true
        
        // Has master admin?
        let users : [MNUser] = try await MNUser.query(on: db)
             .filter(\.$domain == AppServer.DEFAULT_DOMAIN)
             .range(..<2) // .top(1)
             .all() // Fields to return
        var admin : MNUser
        if users.count > 0 /* found */, let user = users.first {
            dlog?.info("prefillUserDataIfNeeded: found existing admin user: \(user.description)")
            //if dlog?.isVerboseActive == true {
            //    user.logPropsDescriptionMap()
            //}
            admin = user
        } else {
            // users.count == 0 // not found
            admin = MNUser()
            admin.displayName = AppServer.DEFAULT_ADMIN_DISPLAY_NAME
            admin.domain = AppServer.DEFAULT_DOMAIN
            admin.avatarURL = URL(string: "/images/avatars/admin.png")
        }
        
        // Save user: (we need the id in the db for the relations):
        try await admin.save(on: db)
        
        // Add login:
        if admin.$logins.value?.count == 0 || RESET_LOGIN_INFO {
            dlog?.info("prefillUserDataIfNeeded: adding / updaing login info:")
            
            let loginInfo = MNLoginInfo()
            loginInfo.$user.id = admin.id
            try loginInfo.setLoginPwdHashed(app: app.vaporApplication!, pwdClear: AppServer.DEFAULT_ADMIN_IIP_PWD)
            
            // Set PII
            let pii = MNUserPII(user: admin, loginInfo: loginInfo, type: .name, piiValue: AppServer.DEFAULT_ADMIN_IIP_USERNAME)
            
            // Save login info
            try await loginInfo.save(on: db)
            
            // A new model can be added to this relation using the create method.
            // Example of adding a new model to a relation.
            // Set PII into loginInfo
            try await loginInfo.$loginPII.create(pii, on: db)
            
            // Save pii: (we need the id in the db for the relations):
            try await pii.save(on: db)

            // Set login into the admin user
            admin.$logins.value = [loginInfo]
            
            // re-save
            try await admin.save(on: db) // second save !?
        }
    }
    
    // MARK: Public
    public func prefillDataIfNeeded(app:AppServer, db:Database) {
        dlog?.verbose("prefillDataIfNeeded")
        if AppPrefillData.wasPrefilled == false {
            Task {
                do {
                    try await self.prefillUserDataIfNeeded(app: app, db: db)
                    try await self.prefillRRabacDataIfNeeded(app: app, db: db)
                } catch let error {
                    let appError = AppError(code: .db_failed_init, reason: "Failed prefillDataIfNeeded", underlyingError: error)
                    dlog?.note("prefillDataIfNeeded threw error: \(appError.description)\n relected error: \(String(reflecting: error))")
                }
                
                // Save settings
                AppPrefillData.wasPrefilled = true
                app.settings?.saveIfNeeded()
            }
        } else {
            dlog?.verbose(log: .note, "prefillDataIfNeeded: DB was already prefilled w/ admin etc.")
        }
    }
}
