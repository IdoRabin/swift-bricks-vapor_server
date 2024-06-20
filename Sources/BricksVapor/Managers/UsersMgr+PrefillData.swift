//
//  UsersMgr+PrefillData.swift
//
//
//  Created by Ido on 17/01/2024.
//

import Foundation
import Fluent
import Logging
import MNUtils

fileprivate let dlog : Logger? = Logger(label:"UsersMgr")// ?.setting(verbose: false)

extension UsersMgr /* prefill data */ {
    // MARK: Types
    // MARK: Const
    // MARK: Static
    // MARK: Properties / members
    // MARK: Private
    private func checkIfUserExists(_ username: String, db:Database) async throws -> Bool {
        let user = try await User.query(on: db)
            .filter(\.$username == username)
            .first()
        return user?._$idExists ?? false
    }
    
    fileprivate func prefillUser(_ user:User, app:AppServer, db:Database) async throws {
        guard try await !self.checkIfUserExists(user.username, db: db) else {
            dlog?.note("prefillUser [\(user.username)] already exists")
            return
        }
        try await user.save(on: db)
    }
    
    // MARK: Lifecycle
    // MARK: Public
    func prefillAdmin(app:AppServer, db:Database) async throws {
        let avatar = "/images/avatars/admin.png"
        let user = try User.create(from: UserSignup(username: "admin", password: "admin", avatarURL: avatar))
        try await self.prefillUser(user, app: app, db: db)
    }
    
    func prefillDebugUsers(app:AppServer, db:Database) async throws {
        guard Debug.IS_DEBUG else {
            return
        }
        
        // let noAvatar = "/images/avatars/no_avatar.png"
        let debugAvatar = "/images/avatars/debug.png"
        for signup in [
            UserSignup(username: "idorabin", password: "12345678", avatarURL: debugAvatar)
        ] {
            // For loop:
            let user = try User.create(from: signup)
            try await self.prefillUser(user, app: app, db: db)
        }
    }
    
}
