//
//  BrickTemplateType.swift
//  bricks
//
//  Created by Ido on 02/12/2021.
//

import Foundation

enum BrickTemplateType : String, AppModelStrEnum {
    
    // NOTE: AppModelStrEnum MUST have string values = "my_string_value" for each string case.
    case unknown    = "unknown"
    case existing   = "existing"
    case skeleton   = "skeleton"
    
    static var all : [BrickTemplateType] {
        return [.unknown, .existing, .skeleton]
    }
}
