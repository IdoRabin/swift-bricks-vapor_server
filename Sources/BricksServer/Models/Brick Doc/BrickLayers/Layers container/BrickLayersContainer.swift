//
//  BrickLayersContainer.swift
//  Bricks
//
//  Created by Ido on 20/02/2022.
//

import Foundation
import DSLogger
import MNUtils

typealias LayersResult = Result<[BrickLayer], AppError>

fileprivate let dlog : DSLogger? = DLog.forClass("BrickLayersContainer")

extension LayersResult {
    var layers : [BrickLayer]? {
        switch self {
        case .failure: return nil
        case .success(let result): return result
        }
    }
    
    // TODO: Determine if Command pattern is ok for server
//    var asCommandResult : CommandResult {
//        switch self {
//        case LayersResult.failure(let error):  return CommandResult.failure(error)
//        case LayersResult.success(let layers): return CommandResult.success(layers)
//        }
//    }
}

protocol BrickLayersContainer {
    var count : Int {get}
    var minLayerIndex : Int? { get }
    var maxLayerIndex : Int? { get }
    
    // Add / Remove
    func addLayers(layers:[BrickLayer])->LayersResult
    func addLayer(mnUID:BricksLayerUID?, name:String?)->LayersResult
    func removeLayers(mnUIDs:[BricksLayerUID])->LayersResult
    
    // Layer order
    func indexesOfLayers(mnUIDs:[BricksLayerUID])->[BricksLayerUID:Int?]
    func indexOfLayer(mnUID:BricksLayerUID)->Int?
    func indexOfLayer(layer:BrickLayer)->Int?
    func changeLayerOrder(mnUID:BricksLayerUID, toIndex:Int)->LayersResult
    func changeLayerOrderToTop(mnUID:BricksLayerUID)->LayersResult
    func changeLayerOrderToBottom(mnUID:BricksLayerUID)->LayersResult
    
    // Find
    func findLayers(mnUIDs:[BricksLayerUID])->LayersResult
    func findLayers(names:[String], caseSensitive:Bool /* = true? */)->LayersResult
    func findLayers(hidden:Bool?)->LayersResult
    
    // Edit
    func lockLayers(mnUIDs:[BricksLayerUID])->LayersResult
    func unlockLayers(mnUIDs:[BricksLayerUID])->LayersResult
    func selectLayers(mnUIDs:[BricksLayerUID], deseletAllOthers:Bool )->LayersResult
    func deselectLayers(mnUIDs:[BricksLayerUID])->LayersResult
}
