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
    public func authenticateIfPossible(unknownReq req:Vapor.Request) async {
        if !req.auth.has(AppUser.self) {
            do {
                let auth = UserTokenAuthenticator()
                try await auth.authenticate(forUnknownRequest: req)
            } catch let error {
                dlog?.note("[\(self.name)] authenticate(unknownReq:) error: \(error.description)")
            }
        } else {
            dlog?.note("[\(self.name)] authenticate(unknownReq:) already authenticated")
        }
    }
}
