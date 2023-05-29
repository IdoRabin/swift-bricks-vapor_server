//
//  Brick.swift
//  bricks
//
//  Created by Ido on 05/12/2021.
//

import Foundation
import Fluent
import DSLogger
import MNUtils

#if VAPOR
import Vapor
#endif

fileprivate let dlog : DSLogger? = DLog.forClass("Brick")

protocol Changable : AnyObject {
    func didChange(sender:Any, context:String, propsAndVals:[String:String])
}

final class Brick : Codable, CustomDebugStringConvertible {
    
    @Group(key: CodingKeys.info.fieldKey)
    var info : BrickBasicInfo
    
//    @Group(key: CodingKeys.settings.fieldKey)
//    var settings : BrickSettings
//
//    @Group(key: CodingKeys.stats.fieldKey)
//    var stats : BrickStats
//
//    @Group(key: CodingKeys.layers.fieldKey)
//    var layers : BrickLayers
    
    enum CodingKeys : String, CodingKey {
        case id         = "id"
        case info       = "doc_info"
//        case settings   = "doc_settings"
//        case stats      = "doc_stats"
//        case layers     = "doc_layers"
        
        var fieldKey : FieldKey {
            return .string(self.rawValue)
        }
    }
    
    @SkipEncode
    private var _isNeedsSaving : Bool = false
    var isNeedsSaving : Bool {
        get {
            guard _isNeedsSaving == false else {
                return true // needs saving
            }
//          TODO: temp  guard self.stats.modificationsCount > 0 else {
//                return false // not a draft
//            }
            
            guard let lastSaved = self.info.lastSavedDate else { return true }
            if let modified = info.lastModifiedDate, modified > lastSaved {
                return true // needs saving
            }
            return false
        }
    }
    
    func setNeedsSaving(sender:Any, context:String, propsAndVals:[String:String]) {
        self.didChange(sender: sender, context:context, propsAndVals: propsAndVals)
    }
    
    // MARK: Identifiable / BUIDable / Vapor "Model" conformance
    @ID(key:.id) // @ID is a Vapor/Fluent ID wrapper for Model protocol, and Identifiable
    var id : UUID?
    
    var mnUID : BrickDocUID? {
        guard let uid = self.id else {
            return nil
        }
        return nil // uncomment: BrickDocUID(uid: uid)
    }
    
    // MARK: Lifecycle
    // Vapor Model requires implementing an empty init()
    init() {
        info = BrickBasicInfo()
//        settings = BrickSettings()
//        stats = BrickStats()
//        layers = BrickLayers()
    }
    
    // MARK: Decodable
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.info = try container.decode(BrickBasicInfo.self, forKey: .info)
//        self.settings = try container.decode(BrickSettings.self, forKey: .settings)
//        self.stats = try container.decode(BrickStats.self, forKey: .stats)
//        self.layers = try container.decode(BrickLayers.self, forKey: .layers)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(info, forKey: .info)
//        try container.encode(settings, forKey: .settings)
//        try container.encode(stats, forKey: .stats)
//        try container.encode(layers, forKey: .layers)
    }
    
    
    // MARK: CustomDebugStringConvertible
    var debugDescription: String {
        get {
            return "\(info.debugDescription.replacingOccurrences(ofFromTo: ["\(BrickBasicInfo.self)":"\(Brick.self)"]))"
        }
    }
    
    static func sanitize(_ str : String?)->String? {
        guard var result = str, result.count > 0 else {
            return nil
        }
        result = result.replacingOccurrences(ofFromTo: [
            "drop table" : "fat chance",
            "DROP TABLE" : "fat chance",
        ])
        result = result.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters).union(.symbols))
        if result.count == 0 {
            return nil
        }
        return result
    }
    
    func sanitize(_ str : String?)->String? {
        return Self.sanitize(str)
    }
}

extension Brick : Changable {
    func didChange(sender: Any, context: String, propsAndVals: [String : String]) {
        dlog?.info("didChange [\(self)] context: \(context) props:\(propsAndVals.keysArray.descriptionsJoined)")
        self.info.lastModifiedDate = Date()
//      TODO: Temp comment  self.stats.modificationsCount += 1
        self._isNeedsSaving = true
    }
}

extension Brick : JSONSerializable {
    // all implemented already
}
