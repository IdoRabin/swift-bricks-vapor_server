//
//  CgfAppErrorMiddleware.swift
//  
//
//  Created by Ido on 03/07/2023.
//

import Foundation
import Vapor
import Logging
import MNUtils
fileprivate let dlog : Logger? = Logger(label:"CgfAppErrorMiddleware") // ?.setting(verbose: false)

extension AppConfigurator {
    
    func configAppErrorMiddleware() {
        guard let app = AppServer.shared.vaporApplication else {
            dlog?.note("failed: vapor app not found!")
            return
        }
        
        // === Error handling middleWre: (default is set with ErrorMiddleware) ===
        // NOTE: custom Error middleware should be added early, but still requires CORSMiddleware to be added BEFORE this error middleware
        app.middleware.use(AppErrorMiddleware.default(environment: app.environment))
    }
}
