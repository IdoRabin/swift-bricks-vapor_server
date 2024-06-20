//
//  CfgFileMiddleware.swift
//  
//
//  Created by Ido on 03/07/2023.
//

import Foundation
import Vapor
import Logging
import MNUtils
fileprivate let dlog : Logger? = Logger(label:"CfgFileMiddleware") // ?.setting(verbose: false)

extension AppConfigurator {
    func configFileMiddleware() {
        guard let app = AppServer.shared.vaporApplication else {
            dlog?.note("failed: vapor app not found!")
            return
        }
        
        // Also need to setup working directory in Edit Scheme -> Options -> Working Directory to app root path (where the pakage sits)
        // This alows serving public files (such as faviocn.ico etc)
        app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    }
}
