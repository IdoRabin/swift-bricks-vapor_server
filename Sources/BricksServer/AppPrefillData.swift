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

import MNSettings   // AppSettable
import MNVaporUtils // contains some needed fluent models
import RRabac       // contains some needed fluent models


fileprivate let dlog : DSLogger? = DLog.forClass("AppPrefillData")?.setting(verbose: false)

class AppPrefillData {
    
    // MARK: Properties
    @AppSettable(key: "AppPrefillData.wasPrefilled", default: false) static var wasPrefilled : Bool
    @AppSettable(key: "noCatDebugTestTry", default: false) static var noCatDebugTestTry : Bool
    
    // MARK: Private
    private func prefillRRabacDataIfNeeded(app:AppServer, db:Database) async throws {
        guard let rrabac = app.vaporApplication?.middleware.getMiddleware(ofType: RRabacMiddleware.self) else {
            dlog?.note("prefillRRabacDataIfNeeded failed finding RRabacMiddleware instance in app.")
            return
        }
        
        dlog?.verbose("prefillRRabacDataIfNeeded \(rrabac)")
    }
    
    // MARK: Public
    public func prefillDataIfNeeded(app:AppServer, db:Database) {
        dlog?.verbose("prefillDataIfNeeded(app:db:)")
        if AppPrefillData.wasPrefilled == false {
            Task {
                do {
                    try await AppServer.shared.users?.prefillAdminUsersData(db: db, user: nil)
                    try await AppServer.shared.users?.prefillDebugUsersDataIfNeeded(db: db)
                    try await self.prefillRRabacDataIfNeeded(app: app, db: db)
                } catch let error {
                    let appError = AppError(code: .db_failed_init, reason: "Failed prefillDataIfNeeded", underlyingError: error)
                    dlog?.note("prefillDataIfNeeded threw error: \(appError.description)\n reflected error: \(String(reflecting: error))")
                }
                
                // Save settings
                AppPrefillData.wasPrefilled = true
                
                // TODO: Re-implement
                // await app.settings?.saveIfNeeded()
            }
        } else {
            dlog?.verbose(log: .note, "prefillDataIfNeeded: DB was already prefilled w/ admin etc.")
        }
    }
}
