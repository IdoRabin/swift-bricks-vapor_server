//
//  PathComponentEx.swift
//  bserver
//
//  Created by Ido on 23/10/2022.
//

import Foundation
import RoutingKit

// extending Vapor RoutingKit PathComponent
extension RoutingKit.PathComponent : Codable, Hashable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self.init(stringLiteral: string)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
    
    // MARK: Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.description)
    }
    
    // MARK: Equatable
    public static func == (lhs: RoutingKit.PathComponent, rhs: RoutingKit.PathComponent) -> Bool {
        return lhs.description == rhs.description
    }
}

extension Sequence where Element == RoutingKit.PathComponent {
    var fullPath:String {
        return "/" + self.descriptions().joined(separator: "/")
    }
}

extension Array where Element == RoutingKit.PathComponent {
    var fullPath:String {
        return self.map { elem in
            "\(elem)"
        }.joined(separator: "/")
        
        // We hate $0 notation!
        // return self.map { "\($0)" }.joined(separator: "/")
    }
}
