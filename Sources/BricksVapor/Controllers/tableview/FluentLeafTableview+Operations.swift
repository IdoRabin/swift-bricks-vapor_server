//
//  FluentLeafTableview+Operations.swift
//
//
//  Created by Ido on 19/02/2024.
//

import Foundation
import MNUtils

public extension FluentLeafTableview {
    struct Operations: OptionSet, Codable, Hashable, Equatable {
        public  let rawValue: Int
        
        static let `delete` = Operations(rawValue: 1 << 0)
        static let edit = Operations(rawValue: 1 << 1)
        static let copy = Operations(rawValue: 1 << 2)
        static let info = Operations(rawValue: 1 << 3)
        static let search = Operations(rawValue: 1 << 4)
        static let add = Operations(rawValue: 1 << 5)
        static let subtract = Operations(rawValue: 1 << 6)
        
        static let selectDeselect = Operations(rawValue: 1 << 10)
        static let deselectSelect = Operations(rawValue: 1 << 11)
        static let enableDisable = Operations(rawValue: 1 << 12)
        static let disableEnable = Operations(rawValue: 1 << 13)
        static let hideShow = Operations(rawValue: 1 << 14)
        static let showHide = Operations(rawValue: 1 << 15)
        static let more = Operations(rawValue: 1 << 16)
        
        static let actions = Operations(rawValue: 1 << 20)
        static let cancel = Operations(rawValue: 1 << 21)
        static let approve = Operations(rawValue: 1 << 22)
        static let reject = Operations(rawValue: 1 << 23)
        static let note = Operations(rawValue: 1 << 24)
        static let warning = Operations(rawValue: 1 << 25)
        static let options = Operations(rawValue: 1 << 26)
        
        public static let all: Operations = [
            .delete, .edit, .copy, .info, .search, .add, .subtract,
            .selectDeselect, .deselectSelect, .enableDisable, .disableEnable, .hideShow, .showHide, .more,
            .actions, .cancel, .approve, .reject, .note, .warning, .options
        ]
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        var name : String {
            guard self.elementsCount == 1 else {
                preconditionFailure("More than one element in FluentLeafTableview.Operations OptionSet. \(self)")
            }
            return "\(self)"
        }
        var names : [String] {
            return self.elements.map { operation in
                operation.name
            }
        }
        
        var accessibilityAriaLabel : [String] {
            switch self {
            case .delete:   return ["Delete"]
            case .edit:     return ["Edit"]
            case .copy:     return ["Copy"]
            case .info:     return ["Info"]
            case .search:   return ["Search"]
            case .add:      return ["Add"]
            case .subtract: return ["Remove"]
                
            case .selectDeselect:   return ["Select", "Deselect"]
            case .deselectSelect:   return ["Deselect", "Select"]
            case .enableDisable:    return ["Enable", "Disable"]
            case .disableEnable:    return ["Disable", "Enable"]
                
            case .hideShow:         return ["Hide", "Show"]
            case .showHide:         return ["Show", "Hide"]
            case .more:             return ["More..."]
                
            case .actions:          return ["Actions..."] //  should it be ? "three-dots-vertical"
            case .cancel:           return ["Cancel"]
            case .approve:          return ["Approve"]
            case .reject:           return ["Reject"]
            case .note:             return ["Take Notice"]
            case .warning:          return ["Warning"]
            case .options:          return ["Options"]
            default:
                return []
            }
        }
        
        var key : String {
            switch self {
            case .delete:   return "Delete"
            case .edit:     return "Edit"
            case .copy:     return "Copy"
            case .info:     return "Info"
            case .search:   return "Search"
            case .add:      return "Add"
            case .subtract: return "Remove"
                
            case .selectDeselect:   return "Select|Deselect"
            case .deselectSelect:   return "Deselect|Select"
            case .enableDisable:    return "Enable|Disable"
            case .disableEnable:    return "Disable|Enable"
                
            case .hideShow:         return "Hide|Show"
            case .showHide:         return "Show|Hide"
            case .more:             return "More..."
                
            case .actions:          return "Actions..." //  should it be ? "three-dots-vertical
            case .cancel:           return "Cancel"
            case .approve:          return "Approve"
            case .reject:           return "Reject"
            case .note:             return "Take Notice"
            case .warning:          return "Warning"
            case .options:          return "Options"
            default:
                return ""
            }
        }
        
        /// Bootstrap icon names
        /// https://icons.getbootstrap.com/ for icons ~ v1.11.3
        var bootstrapIconName : [String] {
            // "toggle-off" , "toggle-on"
            
            switch self {
            case .delete:   return ["trash-3-fill"]
            case .edit:     return ["pencil-fill"]
            case .copy:     return ["copy"]
            case .info:     return ["info"]
            case .search:   return ["search"]
            case .add:      return ["plus"]
            case .subtract: return ["dash"]
                
            case .selectDeselect:   return ["circle", "check-circle"]
            case .deselectSelect:   return ["check-circle", "circle"]
            case .enableDisable:    return ["toggle-on", "toggle-off"]
            case .disableEnable:    return ["toggle-off", "toggle-on"]
                
            case .hideShow:         return ["eye-slash-fill", "eye-fill"]
            case .showHide:         return ["eye-fill", "eye-slash-fill"]
            case .more:             return ["three-dots"]
                
            case .actions:          return ["stars"] //  should it be ? "three-dots-vertical"
            case .cancel:           return ["x-circle"]
            case .approve:          return ["check"]
            case .reject:           return ["x-circle"]
            case .note:             return ["exclamation-triangle-fill"]
            case .warning:          return ["exclamation-octagon-fill"]
            case .options:          return ["sliders"]
            default:
                return []
            }
        }
        
        
        /// Bootstrap theme color name for a given icon returnes either an empty string or a "text-themecolor" bootstrap class
        /// https://getbootstrap.com/docs/5.3/customize/color/ for bootstrap ~ v5.3
        var bootstrapIconColorName : String {
            var result = ""
            
            switch self {
            case .delete:           result = "danger"     // red
            case .selectDeselect:   result = "success"    // green
            case .deselectSelect:   result = "secondary"  // grey - secondary text color
            case .enableDisable:    result = "primary"    // hightlight color
            case .disableEnable:    result = "secondary"  // grey - secondary text color
                
            case .hideShow:         result = "primary"  // hightlight color
            case .showHide:         result = "primary"  // hightlight color
                
            case .actions:          result = "primary" // hightlight color
            case .cancel:           result = "danger"  // red
            case .approve:          result = "success" // green
            case .note:             result = "warning" // orange
            case .warning:          result = "danger"  // red
            default:
                result = "" // assuming the default is "body"
            }
            
            if result.count > 0 {
                // See bootstrap 5.3 theme colors
                result = "text-\(result)"
            }
            return result
        }
        
        /// Returns the bootstrap icon tag for the given operation
        /// for exaple <i class="bi bi-exclamation-triangle-fill text-wraning">
        var bootstrapIconTag : String {
            return "<i class=\"bi bi-\(self.bootstrapIconName) \(self.bootstrapIconColorName) aria-label=\"\(self.accessibilityAriaLabel)\"></i>"
        }
        
        
        /// Relative url to the svg file 
        /// NOTE: assumes svgs exist in the Public/images/svg/icons
        var bootstrapSvgIconURL : String {
            return "/Public/images/svg/icons/\(self.bootstrapIconName).svg "
        }
        
        
        /// An img tag with src as the local relative url to the svg file
        /// NOTE: assumes svgs exist in the Public/images/svg/icons
        var bootstrapIconImgTagWithUrl : String {
            return "<img class=\"\(self.bootstrapIconColorName)\" src=\"\(self.bootstrapSvgIconURL)\" alt=\"\(self.accessibilityAriaLabel)\" aria-label=\"\(self.accessibilityAriaLabel)\" >"
        }
        
        
    }
    
}
