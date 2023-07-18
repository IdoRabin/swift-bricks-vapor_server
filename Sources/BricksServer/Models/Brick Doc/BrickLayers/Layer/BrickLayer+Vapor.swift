//
//  File.swift
//  
//
//  Created by Ido on 14/07/2022.
//

import Foundation

#if VAPOR
import Vapor

extension BrickLayer : Content {}
extension BrickLayer : Authenticatable {}
extension BrickLayer : AsyncResponseEncodable {}

#endif // #if VAPOR

