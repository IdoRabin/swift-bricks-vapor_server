//
//  AppSettings.swift
//
//
//  Created by Ido Rabin for Bricks on 17/1/2024.
//

import Foundation
import MNUtils
import MNVaporUtils
import MNSettings

// TODO: Rewrite the init/registration order for MNSettings and MNSettingsCategoty and MNSettable so that no stupid init with delay timers and etc..

class AppSettingsGlobal : MNSettingsCategory {
    @AppSettable(key:"global.newUsernameAllowedTypes", default:UserPIIType.allCases) var newUsernameAllowedTypes : [UserPIIType]
    @AppSettable(key:"global.existingAllowedTypes", default:UserPIIType.allCases) var existingAllowedTypes : [UserPIIType]
}

class AppSettingsClient : MNSettingsCategory {
    @AppSettable(key:"client.allowsAnalyze", default:true) var allowsAnalyze : Bool
    @AppSettable(key:"client.showsSplashScreenOnInit", default:true) var showsSplashScreenOnInit : Bool
    @AppSettable(key:"client.splashScreenCloseBtnWillCloseApp", default:true) var splashScreenCloseBtnWillCloseApp : Bool
    @AppSettable(key:"client.tooltipsShowKeyboardShortcut", default:true) var tooltipsShowKeyboardShortcut : Bool
}

class AppSettingsServer : MNSettingsCategory {
    @AppSettable(key:"server.requestCount", default:0) var requestCount : UInt64
    @AppSettable(key:"server.requestSuccessCount", default:0) var requestSuccessCount : UInt64
    @AppSettable(key:"server.requestFailCount", default:0) var requestFailCount : UInt64
    @AppSettable(key:"server.respondWithRequestUUID", default:AppSettings._defaultResponWithReqId) var respondWithRequestUUID : Dictionary<BuildType, Bool>
    @AppSettable(key:"server.respondWithSelfUserUUID", default:AppSettings._defaultResponWithSelfUserId) var responWithSelfUserUUID : Dictionary<BuildType, Bool>
    
    // Params that the server should NEVER redirect from one endpoint / page to another:
    @AppSettable(key:"server.paramKeysToNeverRedirect", default:AppSettings._defaultParamKeysToNeverRedirect) var paramKeysToNeverRedirect : [String]
    
    var isShouldRespondWithRequestUUID : Bool {
        return respondWithRequestUUID[BuildType.currentBuildType] ?? true == true
    }
    var isShouldRespondWithSelfUserUUID : Bool {
        return responWithSelfUserUUID[BuildType.currentBuildType] ?? true == true
    }
}

class AppSettingsStats : MNSettingsCategory {
    @AppSettable(key:"stats.launchCount", default:0) var launchCount : Int
    @AppSettable(key:"stats.firstLaunchDate", default:Date()) var firstLaunchDate : Date
    @AppSettable(key:"stats.lastLaunchDate", default:Date()) var lastLaunchDate : Date
}

class AppSettingsDebug : MNSettingsCategory {
    // All default values should be production values.
    @AppSettable(key:"debug.isSimulateNoNetwork", default:false) var isSimulateNoNetwork : Bool
}

class AppSettings : MNSettings {
    // MARK: Types
    // MARK: Const
    // MARK: Static
    static let NAME = "AppSettings"
    
    // isShouldRespondWithRequestUUID for a given build type
    static var _defaultResponWithReqId = Dictionary<BuildType, Bool>(uniqueKeysWithValues:[(BuildType.all, true)])
    
    // isShouldRespondWithSelfUserUUID for a given build type
    static var _defaultResponWithSelfUserId = Dictionary<BuildType, Bool>(uniqueKeysWithValues:[(BuildType.all, true)])
    
    // Parameter keys that are NEVER forwarded when redirecting to another url / page:
    // i.e Params that the server should NEVER redirect from one endpoint / page to another:
    static var _defaultParamKeysToNeverRedirect : [String] = [
        "password", "pwd", "email", "phoneNr", "phoneNumber" ,"phone", "token",
        "accessToken", "user"]
    
    // MARK: Properties / members
    let global = AppSettingsGlobal(customName: "global") // settingsNamed: AppSettings.NAME
    let stats = AppSettingsStats(customName: "stats") // settingsNamed: AppSettings.NAME
    var client : AppSettingsClient? = nil
    var server : AppSettingsServer? = nil
    var debug : AppSettingsDebug? = nil
    
    @AppSettable(key:"AppSettings.loadCount", default:0) var loadCount : UInt64
    
    // MARK: Private
    // MARK: Lifecycle
    required init(named name:String, persistors: [any MNSettingsPersistor] = DEFAULT_PERSISTORS, defaultsProvider:(any MNSettingsProvider)? = nil) {
        
        super.init(named: name, persistors: persistors, defaultsProvider: defaultsProvider)
        
        if Debug.IS_DEBUG || MNUtils.debug.IS_DEBUG {
            debug = AppSettingsDebug(customName: "debug") // settingsNamed: AppSettings.NAME
        }
        
        if AppConstants.IS_VAPOR_SERVER {
            // Is server
            server = AppSettingsServer(settingsNamed: Self.NAME, customName: "server")
        } else {
            // Is client
            client = AppSettingsClient(settingsNamed: Self.NAME, customName: "client")
        }
    }
    
    // MARK: Public
}

