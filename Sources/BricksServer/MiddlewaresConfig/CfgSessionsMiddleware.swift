//
//  CfgSessionsMiddleware.swift
//  
//
//  Created by Ido on 03/07/2023.
//

import Foundation
import Vapor
import DSLogger
import MNUtils
fileprivate let dlog : DSLogger? = DLog.forClass("CfgSessionsMiddleware")?.setting(verbose: false)

extension AppConfigurator {
    func ConfigSessionsMiddleware() {
        guard Vapor.Request.appHasSessionMiddleware else {
            dlog?.note("failed: Vapor.Request.appHasSessionMiddleware is false!")
            return
        }
        guard let app = AppServer.shared.vaporApplication else {
            dlog?.note("failed: vapor app not found!")
            return
        }
        
        // === Sessions record? Session middleware ===
        app.sessions.configuration.cookieName = "X-\(AppConstants.APP_NAME.replacingOccurrences(of: .whitespaces, with: "-"))-Cookie"
        //   app.sessions.use(.fluent) // SESSION DRIVER: Uses the db for the session mapping
        //   app.sessions.use(.redis) // SESSION DRIVER: Uses redis for the session mapping
        app.sessions.use(.memory) // SESSION DRIVER: Use in-memory for session mapping
        // var migration = SessionRecord.migration DOES NOT HAVE : .ignoreExisting()
        // TODO: Check why FAILS the migrations: app.migrations.add(SessionRecord.migration)
        
        app.sessions.configuration.cookieFactory = self.sessionCookieFactory // Configures cookie value creation.
        // Optional: config a session driver:
        // NOTE: !! The session driver should be configured before adding app.sessions.middleware to your application.
        app.middleware.use(app.sessions.middleware)
    }
    
    // Creates the `cookies to follow the user along a single session:
    @Sendable
    fileprivate func sessionCookieFactory (_ sessionID:SessionID) -> HTTPCookies.Value {
        // note: see also ...configuration.cookieName ..
        return .init(string: sessionID.string, isSecure: false)
    }
}
