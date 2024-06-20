//
//  CfgRoutingHistoryMiddleware.swift
//
//
//  Created by Ido on 06/02/2024.
//

import Foundation
import Vapor
import Logging
import MNUtils
import MNVaporUtils

fileprivate let dlog : Logger? = Logger(label:"CfgRoutingHistoryMiddleware") // ?.setting(verbose: false)


extension AppConfigurator {
    func configRoutingHistoryMiddleware() {
        guard let app = AppServer.shared.vaporApplication else {
            dlog?.note("failed: vapor app not found!")
            return
        }
        
        app.middleware.use(MNSessionHistoryMiddleware(maxItemsPerSession:15))
    }
}
