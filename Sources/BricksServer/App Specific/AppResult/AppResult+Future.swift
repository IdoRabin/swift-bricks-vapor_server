//
//  AppResult+Future.swift
//  
//
//  Created by Ido on 10/02/2023.
//

import Foundation
import NIO

extension AppResult /* EventLoopFuture */ {
    func asEventLoppFuture(for loop:EventLoop)->EventLoopFuture<AppResult<Success>> {
        switch self {
        case .success(let successValue):
            return loop.makeSucceededFuture(.success(successValue))
        case .failure(let error):
            return loop.makeSucceededFuture(.failure(fromError: error))
        }
    }
}
