//
//  Clearable.swift
//  bricks
//
//  Created by Ido on 05/12/2021.
//

import Foundation

public enum ClearType {
    case clearAllData
    case clearSyncData
    case debugClear
}

public protocol Clearable {
    func clearData(type:ClearType, completion:Result<Any, Error>?)
}
