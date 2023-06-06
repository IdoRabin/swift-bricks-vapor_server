//
//  BasicDescable.swift
//  Bricks
//
//  Created by Ido on 02/05/2022.
//

import Foundation

protocol BasicDescable {
    var basicDesc : String { get }
}

extension Sequence where Element : BasicDescable {
    var basicDescs : [String] {
        return self.map { item in
            return item.basicDesc
        }
    }
}
