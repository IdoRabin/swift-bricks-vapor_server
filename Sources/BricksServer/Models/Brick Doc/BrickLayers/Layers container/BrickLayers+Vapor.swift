//
//  BrickLayers+Vapor.swift
//  
//
//  Created by Ido on 14/07/2022.
//

import Foundation

#if VAPOR
import Vapor

extension BrickLayers : Content {}
// extension BrickLayers : @unchecked Sendable, Authenticatable {}
extension BrickLayers : AsyncResponseEncodable {}

#endif // #if VAPOR
