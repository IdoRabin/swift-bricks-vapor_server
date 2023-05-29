//
//  BrickStats+Vapor.swift
//  
//
//  Created by Ido on 22/07/2022.
//

import Foundation
import Vapor

import Foundation
#if VAPOR
import Vapor

extension BrickStats : Content {}
extension BrickStats : Authenticatable {}
extension BrickStats : AsyncResponseEncodable {}

#endif // #if VAPOR
