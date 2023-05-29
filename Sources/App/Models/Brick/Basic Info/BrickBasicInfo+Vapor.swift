//
//  File.swift
//  
//
//  Created by Ido on 14/07/2022.
//

import Foundation

#if VAPOR
import Vapor

extension BrickBasicInfo : Content {}
extension BrickBasicInfo : Authenticatable {}
extension BrickBasicInfo : AsyncResponseEncodable {}
#endif
