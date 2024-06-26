//
//  CfgRRabacMiddleware.swift
//  
//
//  Created by Ido on 03/07/2023.
//

import Foundation

import Vapor
import Logging
import MNUtils
import RRabac

fileprivate let dlog : Logger? = Logger(label:"CfgRRabacMiddleware") // ?.setting(verbose: false)

extension AppConfigurator {
    
    func configRRabacMiddleware() {
        guard let app = AppServer.shared.vaporApplication else {
            dlog?.note("failed: vapor app not found!")
            return
        }
        let rrabacMiddleware = RRabacMiddleware.Configured(
            env: app.environment,
            errorWebpagePaths: ["/error"],
            errorPageCheck: nil)
        
        app.middleware.use(rrabacMiddleware, at: .beginning)
    }
    
}

