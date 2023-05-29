//
//  NIODeadlineEx.swift
//  
//
//  Created by Ido on 28/05/2023.
//

import Foundation

// TODO: Remove this duplicate extension (see also in MNUtils)
#if NIO || VAPOR || FLUENT || POSTGRES
import NIOCore

extension NIODeadline /* delayFromNow : TimeInterval */ {
    public static func delayFromNow(_ delay : TimeInterval)->NIODeadline {
        return NIODeadline.now() + .milliseconds(Int64(delay*1000))
    }
}

#endif
