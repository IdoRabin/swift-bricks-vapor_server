//
//  AppRoutingController.swift
//  
//
//  Created by Ido on 19/07/2023.
//

import Foundation
import MNVaporUtils
import Vapor
import DSLogger
import MNUtils

fileprivate let dlog : DSLogger? = DLog.forClass("AppRoutingController")

class AppRoutingController : MNRoutingController {
    public func authenticateIfPossible(request req:Vapor.Request) async {
        if !req.auth.has(AppUser.self) {
            do {
                let auth : UserTokenAuthenticator = req.application.middleware(named: "UserTokenAuthenticator") ?? UserTokenAuthenticator()
                try await auth.authenticate(request: req)
            } catch let error {
                dlog?.note("[\(self.name)] authenticateIfPossible(request:) error: \(error.description)")
            }
        } else {
            dlog?.note("[\(self.name)] authenticateIfPossible(request:) already authenticated")
        }
    }
}
