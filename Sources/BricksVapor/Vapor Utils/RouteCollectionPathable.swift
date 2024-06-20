//
//  RouteCollectionPathable.swift
//
//
//  Created by Ido Rabin for Bricks on 17/1/2024.
//
import Fluent
import MNUtils
import MNVaporUtils
import Vapor

// NOTE: the protocol requires initializeing at least one base path per collection, otherwise crashes.
protocol RouteCollectionPathable {
    var basePaths : [RoutingKit.PathComponent] { get }
    
    // Byt default implementation, will use basePaths.first!
    var basePath: RoutingKit.PathComponent { get }
}

extension RouteCollectionPathable /* default implementation */ {
    var basePath: RoutingKit.PathComponent {
        return basePaths.first!
    }
}
