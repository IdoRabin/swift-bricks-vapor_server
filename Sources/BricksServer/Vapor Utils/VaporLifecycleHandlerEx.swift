//
//  VaporLifecycleHandlerEx.swift
//  
//
//  Created by Ido on 27/05/2023.
//

import Foundation
import Vapor

// NOTE: LifecycleHandler requires implementor to be @Sendable
protocol LifecycleBootableHandler : LifecycleHandler {
    func boot(_ app: Vapor.Application) throws
}

// NOTE: LifecycleHandler requires implementor to be @Sendable
extension LifecycleBootableHandler {
    func boot(_ app: Vapor.Application) throws {}
}
