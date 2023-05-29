//
//  BrickLayers+iOS.swift
//  
//
//  Created by Ido on 07/07/2022.
//

import Foundation

#if !VAPOR // iOS client - UI thingies

extension BrickLayers /* LayerUIInfo only in iOS Client */ {
    struct LayerUIInfo : CodableHashable, JSONSerializable, BasicDescable {
        static let UNNAMED_LAYER_STRING = AppStr.UNNAMED.localized()
        static let TAG_DEFAULT_VAL : Int = -1
        
        let title : String
        let subtitle : String
        let access : BrickLayer.Access
        let visibility : BrickLayer.Visiblity
        let id : LayerUID
        let isUnnamed : Bool
        var tag : Int = TAG_DEFAULT_VAL
        
        static func unnamedTitle(id:LayerUID, index:Int? = 0)->String {
            return Self.UNNAMED_LAYER_STRING + String.NBSP + id.uuidString.safeSuffix(size: 4)
        }
        
        func unnamedTitle(index:Int? = 0)->String {
            return Self.UNNAMED_LAYER_STRING + String.NBSP + self.id.uuidString.safeSuffix(size: 4)
        }
        
        init (layer:BrickLayer, at index:Int, unnamedTitle:String?) {
            id = layer.id
            subtitle = Debug.IS_DEBUG ? layer.id.uuidString : "" // TODO: change this
            access = layer.access
            visibility = layer.visiblity
            isUnnamed = (layer._name?.count ?? 0) == 0
            
            title = (layer._name?.count ?? 0 > 0) ? layer._name! : (unnamedTitle ?? Self.unnamedTitle(id:layer.id))
        }
        
        func titlesAttributedString(attributes:[NSAttributedString.Key : Any]?, isSelected:Bool, hostView:NSView)->NSAttributedString {
            let str = [title, subtitle].joined(separator: " ")
            var attrs = attributes ?? [.font : NSFont.systemFont(ofSize: NSFont.systemFontSize)]
            var txtColor : NSColor = .labelColor
            if isSelected {
                txtColor = isDarkThemeActive(view: hostView) ? .labelColor :  .highlightColor
            }
            if !isSelected && (self.access.isLocked || self.visibility.isHidden) {
                txtColor = txtColor.blended(withFraction: 0.5, of: NSColor.controlBackgroundColor)!
            }
            attrs[.foregroundColor] = txtColor
            let attr = NSMutableAttributedString(string: str, attributes: attrs)
            if self.subtitle.count > 0, attrs.keys.contains(.font) {
                let smallFont = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular) // (attrs[.font] as! NSFont).withSize(9)
                attr.setAtttibutesForStrings(matching: subtitle, attributes: [.font:smallFont,
                                                                              .foregroundColor:txtColor.withAlphaComponent(0.7)])
            }
            return attr
        }
        
        var basicDesc: String {
            var accumStrs : [String] = []
            accumStrs.append("\"\(self.title.isEmpty ? AppStr.UNNAMED.localized() : self.title)\"")
            if self.tag != Self.TAG_DEFAULT_VAL {
                accumStrs.append("tag: \(tag)")
            }
            if self.id.uid.hashValue != 0 {
                accumStrs.append("id: \(id.uuidString)")
            }
            return "<LayerUIInfo " + accumStrs.joined(separator: " ") + " >"
        }
    }
    
    // MARK: LayerUIInfo
    func safeLayerUIInfo(at index:Int)->LayerUIInfo? {
        guard let layer = self.layer(atOrderedIndex:index) else {
            return nil
        }
        
        var result :LayerUIInfo? = nil
        var ttl : String? = nil
        if layer._name?.count ?? 0 > 0 {
            ttl = layer._name
        } else {
            let signifier = layer.id.uuidString.suffix(4) // just
            ttl = LayerUIInfo.UNNAMED_LAYER_STRING + String.NBSP + "\(signifier)"
        }

        DispatchQueue.main.safeSync {
            result = LayerUIInfo(layer:layer, at: index, unnamedTitle: ttl)
        }
        return result
    }
    
    func safeLayersUIInfos()->[Int:LayerUIInfo] {
        var result :[Int:LayerUIInfo] = [:]
        guard self.count > 0, let minn = self.minLayerIndex, let maxx = self.maxLayerIndex else {
            return result
        }
        
        DispatchQueue.main.safeSync {
            for index in minn...maxx {
                if let info = self.safeLayerUIInfo(at: index) {
                    
                    // We set the UI order to be last-top, first-bottom
                    result[index] = info
                }
            }
        }
        return result
    }
    
}

extension Sequence where Element == BrickLayers.LayerUIInfo {
    var titles : [String] {
        return self.map { layerInfo in
            layerInfo.title
        }
    }
}


#endif

