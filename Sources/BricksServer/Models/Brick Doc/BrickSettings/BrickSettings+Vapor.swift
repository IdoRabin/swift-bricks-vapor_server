//
//  File.swift
//  
//
//  Created by Ido on 14/07/2022.
//

import Foundation
#if VAPOR
import Vapor

extension BrickSettings : Content {}
// extension BrickSettings : @unchecked Sendable, Authenticatable {}
extension BrickSettings : AsyncResponseEncodable {}

#endif // #if VAPOR

