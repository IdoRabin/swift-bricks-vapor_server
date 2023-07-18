//
//  AppConstants.swift
//
//  Created by Ido on 10/08/2022.
//

import Foundation
import DSLogger

#if os(OSX)
    import Vapor
#else
    import AppKit
#endif

class AppConstants {
    static let dlog : DSLogger? = DLog.forClass("Constants")
    
    static let IS_VAPOR_SERVER : Bool = {
        var result = false
        #if VAPOR
        result = true
        #endif
        
        // dlog?.info("Constants.IS_SERVER = \(result)")
        return result
    }()
    
    // ==== CLIENT ====
    // Brick files / Brick info
    static let BRICK_FILE_EXTENSION = "bricks"
    static let IS_RTL_LAYOUT = false
    static let CLIENT_SETTINGS_FILENAME = "bricks_app_settings"
    static var APP_NAME = APP_NAME_STR
    static let APP_DISPLAY_NAME = "Bricks"
    
    // ==== SERVER ====
    // Access token:
    static let ACCESS_TOKEN_UUID_STRING_LENGTH = 36
    static let ACCESS_TOKEN_SUFFIX = "_tk"
    static let ACCESS_TOKEN_JWT_KEY = "JWT_KEY_tk"
    static let ACCESS_TOKEN_EXPIRATION_DURATION : TimeInterval = 2 * TimeInterval.SECONDS_IN_A_WEEK
    static let ACCESS_TOKEN_RECENT_TIMEINTERVAL_THRESHOLD : TimeInterval = 20 * TimeInterval.SECONDS_IN_A_MINUTE
    static let BSERVER_APP_SETTINGS_FILENAME = "bserver_app_settings"
    static let BSERVER_VERSION = "1.2.3"
    
    //// CORS: Cross origin allowed URI/IPs/Ports (?)
    static let ALLOWED_DEBUG_CORS_URIS = Debug.IS_DEBUG ? ["http://127.0.0.1:8081/"] : []
    
    // ==== Client + Server ====
    
    static let BASE_64_PARAM_KEY = "e64"
    static let PROTOBUF_PARAM_KEY = "ptb"
    static let PERCENT_ESCAPED_HINTS = [
        "%3D" : "=",
        "%26" : "&",
        "%5F" : "_",
        "%25" : "%",
        "%7C" : "|",
        "%2D" : "-",
        "%20" : " ",
        "%2F" : "/",
    ]
    
    static let PERCENT_DOUBLY_ESCAPED_HINTS = [
        "%253D" : "=",
        "%2526" : "&",
        "%257C" : "|",
        "%252D" : "-",
        "%255F" : "_",
        "%2520" : " ",
        "%252F" : "/",
    ]
}

class Debug {
    #if DEBUG
    static let IS_DEBUG = true // TODO: Check if IS_DEBUG should be an @inlinable var ?
    #else
    static let IS_DEBUG = false // TODO: Check if IS_DEBUG should be an @inlinable var ?
    #endif
    
    static let RESET_DB_ON_INIT = Debug.IS_DEBUG && true // Will wipe
    static let RESET_SETTINGS_ON_INIT = Debug.IS_DEBUG && false
    
    static func StringOrNil(_ str:String)->String? {
        return Debug.IS_DEBUG ? str : nil
    }
    
    static func StringOrEmpty(_ str:String)->String {
        return Debug.IS_DEBUG ? str : ""
    }
}

extension String {
    public static let NBSP = "\u{00A0}"
    public static let FIGURE_SPACE = "\u{2007}" // “Tabular width”, the width of digits
    public static let IDEOGRAPHIC_SPACE = "\u{3000}" // The width of ideographic (CJK) characters.
    public static let NBHypen = "\u{2011}"
    public static let ZWSP = "\u{200B}" // Use with great care! ZERO WIDTH SPACE (HTML &#8203)
    
    public static let SECTION_SIGN = "\u{00A7}" // § Section Sign: &#167; &#xA7; &sect; 0x00A7
    
    public static let CRLF_KEYBOARD_SYMBOL = "\u{21B3}" // ↳ arrow down and right
}

extension Date {
    public static let SECONDS_IN_A_MONTH : TimeInterval = 86400.0 * 7.0 * 4.0
    public static let SECONDS_IN_A_WEEK : TimeInterval = 86400.0 * 7.0
    public static let SECONDS_IN_A_DAY : TimeInterval = 86400.0
    public static let SECONDS_IN_A_DAY_INT : Int = 86400
    public static let SECONDS_IN_AN_HOUR : TimeInterval = 3600.0
    public static let SECONDS_IN_AN_HOUR_INT : Int = 3600
    public static let SECONDS_IN_A_MINUTE : TimeInterval = 60.0
    public static let MINUTES_IN_AN_HOUR : TimeInterval = 60.0
    public static let MINUTES_IN_A_DAY : TimeInterval = 1440.0
}

extension TimeInterval {
    public static let SECONDS_IN_A_MONTH : TimeInterval = 86400.0 * 7.0 * 4.0
    public static let SECONDS_IN_A_WEEK : TimeInterval = 86400.0 * 7.0
    public static let SECONDS_IN_A_DAY : TimeInterval = 86400.0
    public static let SECONDS_IN_A_DAY_INT : Int = 86400
    public static let SECONDS_IN_AN_HOUR : TimeInterval = 3600.0
    public static let SECONDS_IN_AN_HOUR_INT : Int = 3600
    public static let SECONDS_IN_A_MINUTE : TimeInterval = 60.0
    public static let MINUTES_IN_AN_HOUR : TimeInterval = 60.0
    public static let MINUTES_IN_A_DAY : TimeInterval = 1440.0
}

#if !VAPOR
extension NSView {
    var isDarkThemeActive : Bool {
        if #available(OSX 10.14, *) {
            return self.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua, .vibrantDark]) == .darkAqua
        }
        return false
    }
}

func isDarkThemeActive(view: NSView) -> Bool {

    if #available(OSX 10.14, *) {
        return view.isDarkThemeActive
    }
    
    return false
}
#endif
