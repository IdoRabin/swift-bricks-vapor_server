//
//  BrickLayers.swift
//  Bricks
//
//  Created by Ido on 03/01/2022.
//

import Foundation
import Fluent
import DSLogger
import MNUtils
import MNSettings

fileprivate let dlog : DSLogger? = DLog.forClass("BrickLayers")
fileprivate let dlogNL : DSLogger? = nil // DLog.forClass("BrickLayers+Nearest")

typealias BricksLayerUID = MNUID

// Vapor requires final classes
final class BrickLayers : CodableHashable, BasicDescable, MNUIDable {
    static let mnuidTypeStr: String = "BRK_LYRz"
    
    static let MAX_LAYERS_ALLOWED = 32
    static let MIN_LAYER_NAME_LENGTH = 1
    static let MAX_LAYER_NAME_LENGTH = 128
    
    static let SETTING_ = 128
    @AppSettable(key: "BrickLayers.selectAddedLayer", default: true) static var selectAddedLayer : Bool
    @AppSettable(key: "BrickLayers.selectNearRemovedLayers", default: true) static var selectNearRemovedLayers : Bool
    
    enum CodingKeys : String, CodingKey, CaseIterable {
        case id                 = "id"
        case orderedLayers      = "layers"
        
        var fieldKey : FieldKey {
            return .string(self.rawValue)
        }
    }
    
    // MARK: Properties
    
    @Field(key: CodingKeys.orderedLayers.fieldKey)
    private(set) var orderedLayers : [BrickLayer]
   
    // MARK: Privare
    @SkipEncode
    private(set) var isBusy = false
    
    var isIdle : Bool {
        return !self.isBusy
    }
    
    // MARK: Lifecycle
    // MARK: Public
    var id: UUIDv5?
    
    // MARK: Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(orderedLayers)
    }
    
    /// all layrs that are selected, in the same order they appear in orderedLayers. Equivalent to filtering the orderedLayers array with where: layer.selection.isSelected
    var selectedLayers : [BrickLayer] {
        return self.orderedLayers.filter(selection: .selected)
    }
    
    var selectedLayersByIndex : [Int:BrickLayer] {
        return self.layersByOrderIndex { layer in
            layer.isSelected
        }
    }
    
    // MARK: Equatable
    static func == (lhs: BrickLayers, rhs: BrickLayers) -> Bool {
        return lhs.orderedLayers == rhs.orderedLayers
    }
    
    // MARK: Equality
    var count : Int {
        return orderedLayers.count
    }
    
    var safeCount : Int {
        var result : Int = 0
        DispatchQueue.main.safeSync {[self] in
            result = orderedLayers.count
        }
        return result
    }
    
    // MARK: Count and layers access
    var layersByOrderIndex : [Int:BrickLayer] {
        var result : [Int:BrickLayer]  = [:]
        orderedLayers.forEachIndex { index, layer in
            result[index] = layer
        }
        return result
    }
    
    func layersByOrderIndex(filter test:(BrickLayer)->Bool)->[Int:BrickLayer] {
        var result : [Int:BrickLayer]  = [:]
        orderedLayers.forEachIndex { index, layer in
            if test(layer) {
                result[index] = layer
            }
        }
        return result
    }
    
    /// find a layer with the given id, or nil
    /// - Parameter id: id to search for
    /// - Returns: the first found layer with the given id
    func layer(byId id:BricksLayerUID)->BrickLayer? {
        // NOTE: findLayer(byId id:LayerUID)->BrickLayer? calls this function
        return self.orderedLayers.first(mnUID: id)
    }

    /// find a layer at the given order index, or nil if out of bounds
    /// - Parameter atOrderedIndex: index at orderedLayers array
    /// - Returns: the first found layer at the given index, or nil if out of bounds
    func layer(atOrderedIndex index:Int)->BrickLayer? {
        guard self.count > 0, let minn = self.minLayerIndex, let maxx = self.maxLayerIndex else {
            return nil
        }
        guard index >= minn && index <= maxx else {
            dlog?.note("layer(at index:\(index) out of bounds [\(minn)...\(maxx)]")
            return nil
        }
        return orderedLayers[index]
    }
    
    // Convenience
    subscript (index:Int) -> BrickLayer? {
        return self.layer(atOrderedIndex: index)
    }
    
    func count(visiblility:BrickLayer.Visiblity)->Int {
        return 0// orderedLayers.filter(visiblility: visiblility).count
    }

    func count(access:BrickLayer.Access)->Int {
        return 0// return orderedLayers.filter(access: access).count
    }
    
    var basicDesc : String {
        return "<\(type(of: self)) \(MemoryAddress(of: self)) \(self.count) layers>"
    }
}

extension BrickLayers : BrickLayersContainer {
    
    func indexesOfLayers(mnUIDs:[BricksLayerUID])->[BricksLayerUID:Int?] {
        var result : [BricksLayerUID:Int] = [:]
        for mnUID in mnUIDs {
            let indexOrNil = self.orderedLayers.firstIndex { layer in
                layer.mnUID == mnUID
            }
            
            if Debug.IS_DEBUG && indexOrNil == nil {
                dlog?.note("indexesOfLayers failed to find index of layer buid: \(mnUID) ")
            }
            result[mnUID] = indexOrNil
        }
        return result
    }
    
    func indexOfLayer(mnUID: BricksLayerUID) -> Int? {
        return indexesOfLayers(mnUIDs: [mnUID]).first?.value
    }
    
    func indexOfLayer(layer: BrickLayer) -> Int? {
        guard let mnUIDToFind = layer.mnUID, self.validateMNUID(mnUIDToFind) else {
            return nil
        }
        return indexesOfLayers(mnUIDs: [mnUIDToFind]).first?.value
    }
    
    func findLayersNearestTo(mnUIDs:[BricksLayerUID], minGrow:UInt = 0, maxGrow:UInt = 2)->[BrickLayer] {
        var result : [BrickLayer] = []
        
        guard self.count > 0 else {
            return result
        }
        
        guard maxGrow <= self.count else {
            dlog?.warning("findLayersNearestTo: maxGrow \(maxGrow) cannot be >= count \(self.count) of all layers")
            return result
        }
        
        guard minGrow < maxGrow else {
            dlog?.warning("findLayersNearestTo: minGrow (\(minGrow) sould be smaller than maxGrow (\(maxGrow)")
            return result
        }
        
        guard mnUIDs.count < self.count else {
            dlog?.warning("findLayersNearestTo: \(mnUIDs.descriptionsJoined) ids cound must be smaller than layers count")
            return result
        }
        
        guard mnUIDs.isEmpty == false else {
            dlog?.warning("findLayersNearestTo: \(mnUIDs.descriptionsJoined) at least one input id needed")
            return result
        }
        
        
        let byIndex = self.layersByOrderIndex { layer in
            if let buid = layer.mnUID, layer.validateMNUID(buid) {
                return mnUIDs.contains(buid)
            } else {
                dlog?.warning("findLayersNearestTo: failed: layer \(layer.description) has no id")
                return false
            }
        }
        
        if byIndex.count == mnUIDs.count {
            let indexes = byIndex.keysArray.sorted()
            
            dlogNL?.info("findLayersNearestTo: \(mnUIDs.descriptionsJoined) at: \(indexes.descriptionsJoined)")
            dlogNL?.info("findLayersNearestTo START")
            DLog.indentStart(logger: dlogNL)
            
            // All layers in ids were found in self layers ordered array)
            let minGrow = clamp(value: minGrow, lowerlimit: 1, upperlimit: maxGrow)
            let maxGrow = clamp(value: maxGrow, lowerlimit: minGrow + 1, upperlimit: max(maxGrow, minGrow + 1))
            var wasFound = false
            for adex in minGrow...maxGrow { // Attempts with as minimum
                for sign in [-1, +1] {
                    let add = sign * Int(adex)
                    for index in indexes {
                        let idx = index + add
                        if idx >= 0 && idx < self.count {
                            let layer = self.layer(atOrderedIndex: idx)
                            
                            if let layer = layer, let layerMNUID = layer.mnUID, layer.validateMNUID(layerMNUID) && !mnUIDs.contains(layerMNUID) {
                                result.append(layer)
                                wasFound = true
                            }
                            
                            dlogNL?.successOrFail(condition: wasFound, "findLayersNearestTo: at index: \(idx) layer: \((layer?.mnUID).descOrNil)")
                        }
                        
                        if wasFound { break }
                    }
                    if wasFound { break }
                }
                if wasFound { break }
            }
            DLog.indentEnd(logger: dlogNL)
            dlogNL?.successOrFail(condition: wasFound, "findLayersNearestTo END")
        } else {
            dlog?.warning("findLayersNearestTo: \(mnUIDs.descriptionsJoined) failed finding some ids: \( (self.findLayers(mnUIDs: mnUIDs).layers?.mnUIDs.descriptionsJoined).descOrNil)")
        }
        
        return result
    }
    
    private func operateOnLayers(byMNUIDs mnUIDs:[BricksLayerUID], block:([BrickLayer])->LayersResult)->LayersResult {
        let foundLayers = self.findLayers(mnUIDs: mnUIDs)
        switch foundLayers {
        case .failure:
            return foundLayers
        case .success(let layers):
            return block(layers)
        }
    }
    
    // MARK: Public from protocol
    func addLayers(layers: [BrickLayer]) -> LayersResult {
        guard self.count < Self.MAX_LAYERS_ALLOWED else {
            return .failure(AppError(code:.doc_layer_insert_failed, reason: "Max layers count reached: \(Self.MAX_LAYERS_ALLOWED), cannot add more."))
        }
        
        // Determine the index to insert the new layer/s:
        var indexToInsertAt : Int = 0 // no layer selected: insert at top
        if self.selectedLayers.count > 0 {
            
            // Selected layers: insert above the topmost selected layer
            let indexes = self.indexesOfLayers(mnUIDs: self.selectedLayers.mnUIDs).compactMap { tuple in
                return tuple.value
            } as [Int]
            indexToInsertAt = indexes.min() ?? 0
        }
        
        // Actually Add layers:
        var toAdd = layers
        let existing = layers.filter(mnUIDs: orderedLayers.mnUIDs)
        if existing.count > 0 {
            if existing.count == layers.count {
                dlog?.warning("Layers already exist in the layers ordered list: \(existing.mnUIDs.descriptionsJoined)")
            } else {
                dlog?.warning("Some layers already exist in the layers ordered list: \(existing.mnUIDs.descriptionsJoined)")
            }
            toAdd = layers.excluding(mnUIDs: existing.mnUIDs)
        }
        
        if toAdd.count > 0 || layers.count == 0 {
            if indexToInsertAt >= 0 && indexToInsertAt <= layers.count {
                orderedLayers.insert(contentsOf: toAdd, at: indexToInsertAt)
            } else {
                orderedLayers.append(contentsOf: toAdd)
            }
            
            // Change selection if needed
            if Self.selectAddedLayer { // App Settings
                _ = self.selectLayers(mnUIDs: toAdd.mnUIDs, deseletAllOthers: true)
            }
            
            return .success(toAdd)
        } else {
            return .failure(AppError(code:.doc_layer_insert_failed, reason: "0 layers to add (excluded \(existing.count) already existing)"))
        }
        // return .failure(AppError(code:.doc_layer_insert_failed, reason: "Unknown error"))
    }
    
    func addLayer(mnUID: BricksLayerUID?, name: String?) -> LayersResult {
        let layr = BrickLayer(uid: mnUID, name: name)
        return self.addLayers(layers: [layr])
    }
   
    func removeLayers(mnUIDs: [BricksLayerUID]) -> LayersResult {
        return self.operateOnLayers(byMNUIDs: mnUIDs) { layers in
            
            var nearestMNUIDs : [BricksLayerUID] = []
            let isSelectNearestLayers = Self.selectNearRemovedLayers
            if isSelectNearestLayers { // App Settings
                let maxgrow = UInt(max(self.count - 1, 2))
                nearestMNUIDs = self.findLayersNearestTo(mnUIDs: mnUIDs, minGrow: 0, maxGrow: maxgrow).mnUIDs
            }
            
            if orderedLayers.remove(objects: layers) == mnUIDs.count {
                
                // Change selection if needed
                if isSelectNearestLayers, nearestMNUIDs.count > 0 { // App Settings
                    _ = self.selectLayers(mnUIDs: nearestMNUIDs, deseletAllOthers: true)
                }
                
                return .success(layers)
            } else {
                return .failure(AppError(code:.doc_layer_delete_failed, reason: "Some layers were not deleted!"))
            }
        }
    }
    
    /// Move layer in the "stack" order of the layers to a new index
    /// - Parameters:
    ///   - id:id of the layer to move
    ///   - toIndex: new index to set the layer in: NOTE the new index should be given in old array indexes (i.e as if was not yet removed from prev. location)
    /// - Returns: succes with the moved layer or the failure error
    func changeLayerOrder(mnUID: BricksLayerUID, toIndex: Int) -> LayersResult {
        let curIndex = self.indexOfLayer(mnUID: mnUID)
        let layer = self.orderedLayers.filter(mnUIDs: [mnUID]).first
        if let curIndex = curIndex, let layer = layer {
            if curIndex == toIndex {
                // No need to mode
                return .success([layer])
            } else {
                orderedLayers.remove(at: curIndex)
                var newIndex = toIndex
                if newIndex > curIndex {
                    newIndex -= 1 // was removed, we fix the index
                }
                if newIndex > -1 && newIndex <= self.orderedLayers.count {
                    orderedLayers.insert(layer, at: newIndex)
                }
                return .success([layer])
            }
        }
        
        return .failure(AppError(code:.doc_layer_move_failed, reason: "Layer id \(mnUID) was not found"))
    }
    
    func changeLayerOrderToTop(mnUID: BricksLayerUID) -> LayersResult {
        return self.changeLayerOrder(mnUID: mnUID, toIndex: self.count)
    }
    
    func changeLayerOrderToBottom(mnUID: BricksLayerUID) -> LayersResult {
        return self.changeLayerOrder(mnUID: mnUID, toIndex: 0)
    }
    
    private func findLayers(test: (BrickLayer)->Bool) -> LayersResult {
        guard self.orderedLayers.count > 0 else {
            return .failure(AppError(code:.doc_layer_search_failed, reason: "Not layers to search in"))
        }
        var result : [BrickLayer] = []
        for layer in orderedLayers {
            if test(layer) {
                result.append(layer)
            }
        }
        return .success(result.uniqueElements())
    }
    
    func findLayers(at indexes: IndexSet) -> LayersResult {
        return self.findLayers { layer in
            if let index = self.indexOfLayer(layer: layer),
               indexes.contains(index) {
               return true // test success: layer index in the index set
            }
            return false // test failed
        }
    }
    
    func findLayer(byId id:BricksLayerUID)->BrickLayer? {
        // Convenience
        return self.layer(byId: id)
    }
    
    func findLayers(mnUIDs: [BricksLayerUID]) -> LayersResult {
        return self.findLayers { layer in
            if let layerMNUID = layer.mnUID, self.validateMNUID(layerMNUID) {
                return mnUIDs.contains(layerMNUID)
            } else {
                return false
            }
        }
    }
    
    func findLayers(names: [String], caseSensitive:Bool = true) -> LayersResult {
        return self.findLayers { layer in
            if caseSensitive {
                return names.contains(layer.name ?? "")
            } else {
                return names.lowercased.contains(layer.name?.lowercased() ?? "")
            }
        }
    }
    
    func findLayers(hidden: Bool?) -> LayersResult {
        return self.findLayers { layer in
            layer.isHidden == hidden
        }
    }
    
    func setLayersVisibility(mnUIDs: [BricksLayerUID], newVisibilityState:BrickLayer.Visiblity) -> LayersResult {
        self.operateOnLayers(byMNUIDs: mnUIDs) { layers in
            var changes = 0
            for layer in layers {
                if layer.visiblity != newVisibilityState {
                    layer.visiblity = newVisibilityState
                    changes += 1
                }
            }
            
            return .success(layers)
            //return.failure(AppError(code: .doc_layer_lock_unlock_failed, detail: "set layer locked \(isLocked): \(layers.descriptions().descriptionsJoined)"))
        }
    }
    
    func setLayersAccess(mnUIDs: [BricksLayerUID], newAccessState:BrickLayer.Access) -> LayersResult {
        self.operateOnLayers(byMNUIDs: mnUIDs) { layers in
            var changes = 0
            for layer in layers {
                if layer.access != newAccessState {
                    layer.access = newAccessState
                    changes += 1
                }
            }
            
            return .success(layers)
            //return.failure(AppError(code: .doc_layer_lock_unlock_failed, detail: "set layer locked \(isLocked): \(layers.descriptions().descriptionsJoined)"))
        }
    }
    
    func setLayersSelected(mnUIDs: [BricksLayerUID], selectionState:BrickLayer.Selection) -> LayersResult {
        self.operateOnLayers(byMNUIDs: mnUIDs) { layers in
            var changesCount = 0
            for layer in layers {
                if layer.selection != selectionState {
                    layer.selection = selectionState
                    changesCount += 1
                }
            }
            return .success(layers.filter({ layer in
                layer.isSelected
            }))
            // return.failure(AppError(code: .doc_layer_select_deselect_failed, detail: "set layer selected \(isSelected): \(layers.descriptions().descriptionsJoined)"))
        }
    }
    
    func lockLayers(mnUIDs: [BricksLayerUID]) -> LayersResult {
        return self.setLayersAccess(mnUIDs: mnUIDs, newAccessState: .locked)
    }
    
    func unlockLayers(mnUIDs: [BricksLayerUID]) -> LayersResult {
        return self.setLayersAccess(mnUIDs: mnUIDs, newAccessState: .unlocked)
    }
    
    func selectLayers(mnUIDs:[BricksLayerUID], deseletAllOthers:Bool = false)->LayersResult {
        
        // Set seletion to layers:
        let result1 = self.setLayersSelected(mnUIDs: mnUIDs, selectionState: .selected)
        switch result1 {
        case .success(let layers):
            
            // Deselect other layers
            if deseletAllOthers {
                let deselectIds : Set<BricksLayerUID> = Set(orderedLayers.mnUIDs).subtracting(mnUIDs)
                let result2 = self.setLayersSelected(mnUIDs: deselectIds.allElements(), selectionState: .nonselected)
                switch result2 {
                case .success:
                    return .success(selectedLayers)
                case .failure:
                    return result2
                }
            } else {
                return .success(layers)
            }
        case .failure:
            return result1
        }
    }
    
    func deselectLayers(mnUIDs: [BricksLayerUID]) -> LayersResult {
        self.setLayersSelected(mnUIDs: mnUIDs, selectionState: .nonselected)
    }
    
    var minLayerIndex: Int? {
        return self.count > 0 ? 0 : nil
    }
    
    var maxLayerIndex: Int? {
        return self.count > 0 ? self.count - 1 : nil
    }
    
}

extension Sequence where Element : BrickLayer {

//    var ids : [UUID] {
//        return self.compactMap { layer in
//            return layer.id
//        }
//    }
    
    var mnUIDs : [BricksLayerUID] {
        return self.compactMap { layer in
            if let layerMNUID = layer.mnUID, layer.validateMNUID(layerMNUID) {
                return layerMNUID
            }
            return nil
        }
    }
    
    func filter(access:BrickLayer.Access)->[BrickLayer] {
        return self.filter { layer in
            layer.access == access
        }
    }

    func filter(visiblility:BrickLayer.Visiblity)->[BrickLayer] {
        return self.filter { layer in
            layer.visiblity == visiblility
        }
    }

    func filter(selection:BrickLayer.Selection)->[BrickLayer] {
        return self.filter { layer in
            layer.selection == selection
        }
    }

    func first(mnUID:BricksLayerUID)->BrickLayer? {
        return self.filter { layer in
            layer.mnUID == mnUID
        }.first
    }
    
    func filter(mnUIDs:[BricksLayerUID])->[BrickLayer] {
        return self.filter { layer in
            if let layerMNUID = layer.mnUID, layer.validateMNUID(layerMNUID) {
                return mnUIDs.contains(mnUID:layerMNUID)
            }
            return false
        }
    }

    func filter(names:[String], caseSensitive:Bool = false)->[BrickLayer] {
        let nams = caseSensitive ? names :  names.lowercased
        return self.filter { layer in
            let name = caseSensitive ? layer.name : layer.name?.lowercased()
            return nams.contains(name ?? "")
        }
    }

    func excluding(mnUIDs:[BricksLayerUID])->[BrickLayer] {
        return self.filter { layer in
            if let layerMNUID = layer.mnUID, layer.validateMNUID(layerMNUID) {
                return !mnUIDs.contains(mnUID:layerMNUID)
            }
            return false
        }
    }
    
    func contains(allMNUIDs mnUIDs:[BricksLayerUID])->Bool {
        return self.filter(mnUIDs: mnUIDs).count == mnUIDs.count
    }

    func contains(anyOfMNUIDs mnUIDs:[BricksLayerUID])->Bool {
        return self.filter(mnUIDs: mnUIDs).count > 0 // TODO: Optimize for stopping on first found id
    }

    func contains(allNames names:[String], caseSensitive:Bool = false)->Bool {
        return self.filter(names: names).count == names.count
    }

    func contains(anyOfNames names:[String], caseSensitive:Bool = false)->Bool {
        return self.filter(names: names, caseSensitive: caseSensitive).count > 0 // TODO: Optimize for stopping on first found name
    }
}

#if !VAPOR // iOS Client only!
extension BrickLayers /* Commands - CommandResult */ {
    
    func isLayerNameAllowed(_ newName:Any?, forLayerAt at:Int)->CommandResult {
        if newName.descOrNil.lowercased().contains("nil") {
            // Allow nil name:
            return .success("")
        }
        
        guard let newName = newName as? String else {
            return .failure(AppError(code: .doc_layer_change_failed, detail: "Layer name value is not a string"))
        }
        
        return self.isLayerNameAllowed(newName, forLayerAt: at)
    }
    
    func isLayerNameAllowed(_ newName:String, forLayerAt at:Int)->CommandResult {
        guard at >= 0 && at < self.count else {
            return .failure(AppError(code: .doc_layer_change_failed, detail: "new layer name for layet at index \(at) - is out of bounds."))
        }
        
        // Too loong / short
        guard newName.count >= Self.MIN_LAYER_NAME_LENGTH &&
              newName.count <= Self.MAX_LAYER_NAME_LENGTH else {
                  return .failure(AppError(code: .doc_layer_change_failed, detail: "new layer name too long or short: [\(newName)] should be [\(Self.MIN_LAYER_NAME_LENGTH)...\(Self.MAX_LAYERS_ALLOWED)] chars long."))
        }
        
        return .success(newName)
    }

    /// Check if a dictionary of changes to a gien layer is allowed (permission and all values checked to be legal for assignment)
    /// - Parameters:
    ///   - dic: dictionary of field name (String) and value (Any)
    ///   - layerID: layer id of the layer to change
    /// - Returns: Result succes with the dictionary or failute with an error
    func isAllowedEdit(_ dic:[String:AnyCodable], layerID:LayerUID)->CommandResult {
        guard let layerIndex = self.indexOfLayer(id: layerID) else {
            return .failure(AppError(code: .doc_layer_change_failed, detail: "failed finding layer index for layer: \(layerID)"))
        }
        
        var result : CommandResult = .success(dic)
        
        // Dictionary of changes to apply to the layer:
        for (key, val) in dic {
            var itemResult : CommandResult = .success(val)
            switch key {
            case "name":
                itemResult = isLayerNameAllowed(val, forLayerAt: layerIndex)
            default:
                dlog?.note("isAllowedEdit did not handle case of: [\(key)] changing")
            }
            if itemResult.isFailed {
                result = itemResult
                break
            }
        }
        
        return result
    }
    
    /// Apply a dictionary of changes to a given layer (by id)
    /// NOTE: Assumes isAllowedEdit(dic) was called before this method
    /// - Parameters:
    ///   - dic: dictionary of field name (String) and value (Any)
    ///   - layerID: layer id of the layer to change
    /// - Returns: Result succes with the dictionary or failute with an error
    func applyEdit(_ dic:[String:AnyCodable], layerID:LayerUID)->CommandResult {
        guard let layerIndex = self.indexOfLayer(id: layerID) else {
            return .failure(AppError(code: .doc_layer_change_failed, detail: "applyEdit failed finding layer index for layer: \(layerID)"))
        }
        
        var result : CommandResult = .success(dic)
        
        // Dictionary of changes to apply to the layer:
        for (key, val) in dic {
            var itemResult : CommandResult = .success(val)
            switch key {
            case "name":
                if let anewName = val as? String, let newName = Brick.sanitize(anewName) {
                    self[layerIndex]?._name = newName
                } else if "\(val)".lowercased().contains("nil") {
                    self[layerIndex]?._name = nil
                } else {
                    itemResult = .failure(AppError(code: .doc_layer_change_failed, detail: "applyioEdit - layer name value is not a string"))
                }
            default:
                dlog?.note("applyEdit did not handle case of: [\(key)] changing")
            }
            
            if itemResult.isFailed {
                result = itemResult
                break
            }
        }
        
        return result
    }

}
#endif
