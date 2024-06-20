//
//  CfgAppRedirectMiddleware.swift
//
//
//  Created by Ido on 03/07/2023.
//

import Foundation
import Vapor
import Logging
import MNUtils
import MNVaporUtils

fileprivate let dlog : Logger? = Logger(label:"CfgAppRedirectMiddleware") // ?.setting(verbose: false)


extension AppConfigurator {
    
    func configRedirectMiddleware() throws {
        guard let app = AppServer.shared.vaporApplication else {
            dlog?.note("failed: vapor app not found!")
            return
        }
        
        let redirectRules : [AppRedirectRule] = [
            // All errors in dashboard group are redirected to the dashboard error page:
            try .init(sourceGroupTag: "dashboard", 
                  sourcePath: nil,
                  sourceMethod: .GET, // Web?
                  responseStatii: .nonSuccesses,
                  redirectToPath: "/dashboard/error/",
                  redirectType: .temporary,
                  redirectDirectives: .previousRequestId)
        ]
        
        app.middleware.use(AppRedirectMiddleware(redirectRules: redirectRules))
    }
    
}
