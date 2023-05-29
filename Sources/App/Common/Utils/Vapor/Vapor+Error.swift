//
//  Vapor+Error.swift
//  
//
//  Created by Ido on 16/11/2022.
//

import Foundation
import Vapor

extension Abort {
    init(appErrorCode aeCode:AppErrorCode, reason areason:String? = nil) {
        if aeCode.isHTTPStatus {
            self.init(aeCode.httpStatusCode!)
        } else {
            self.init(.custom(code: UInt(aeCode.code), reasonPhrase: areason ?? aeCode.reason))
        }
    }
}
