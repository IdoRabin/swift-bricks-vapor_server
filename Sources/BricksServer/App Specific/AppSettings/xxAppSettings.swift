//
//  AppSettings.swift
//  Bricks
//
//  Created by Ido Rabin on 24/07/2023.
//  Copyright © 2023 IdoRabin. All rights reserved.
//

import Foundation
import Vapor
import DSLogger
import MNUtils
import MNVaporUtils

// import Codextended

fileprivate let dlog : DSLogger? = DLog.forClass("AppSettings")?.setting(verbose: false)

// A singleton for all app settingsåå, saves and loads from a json file the last saved settings.
// "Other" are all settings properties that are distributed around the app as properties of other classes. They åare still connected and saved into this settings file, under the "other" dictionary.
/*
@globalActor final actor xxAppSettings : AppSettingProvider, JSONFileSerializable {
    
    #if VAPOR
    static let FILENAME = AppConstants.BSERVER_APP_SETTINGS_FILENAME
    #else
    static let FILENAME = AppConstants.CLIENT_SETTINGS_FILENAME
    #endif
    
    // MARK: Singleton / GlobalActor
    private static var _shared : xxAppSettings? = nil
    public static var shared : xxAppSettings {
        if let shared = _shared {
            return shared
        } else if let instance = self.loadFromFile() {
            _shared = instance
            return instance
        } else {
            _shared = xxAppSettings()
            return _shared!
        }
    }
    
    // MARK: Lifecycle
    private init() {
        // rest to defaults:
        if Debug.RESET_SETTINGS_ON_INIT {
            Task {
                await self.resetToDefaults()
            }
        }
        
        dlog?.info("Init \(String(memoryAddressOf: self))")
    }
    
    deinit {
        dlog?.info("deinit \(String(memoryAddressOf: self))")
    }
    
    // MARK: Private Properties / members
    @SkipEncodeSendable private var _changes : [String] = []
    @SkipEncodeSendable private var _isLoading : Bool = false
    @SkipEncodeSendable private var _isBlockChanges : Bool = false
    private var isLoading : Bool {
        get { self._isLoading }
        set {
            if newValue != self._isLoading {
                self._isLoading = newValue
            }
        }
    }
    
    // MARK: Static
    private static var _isLoaded : Bool = false
    private static var _initingShared : Bool = false
    
    
    // MARK: Public Properties / members
    
    
    // MARK: AppSettingProvider
    func noteChange(_ change: String, newValue: Sendable) async {
        dlog?.verbose("changed: \(change) = \(newValue)")
        _changes.append(change + " = \(newValue)")
        
        guard self.isLoaded else {
            return
        }
        
        // "Other" are all settings properties that are distributed around the app as properties of other classes. They are still connected and saved into this settings file, under the "other" dictionary.
        if CodingKeys.isOther(key: change) {
            other[change] = newValue
        }
        
        // debounce
        let eventLoop : EventLoop? = AppServer.shared.vaporApplication?.eventLoopGroup.next()
        eventLoop?.debounce(timeout: 0.1, delay: 0.0, {
            dlog?.info("ha!!")
        })
        // TimedEventFilter.shared.filterEvent(key: "AppSettings.changes", threshold: 0.3, accumulating: change) { changes in
        
//        TimedEventFilter.shared.filterEvent(key: "AppSettings.changes", threshold: 0.2) {
//            if self._changes.count > 0 {
//                 dlog?.verbose("changed: \(self._changes.descriptionsJoined)")
//
//                // Want to save all changes to settings into a seperate log?
//                // Do it here! - use self._changes
//
//                await self.saveIfNeeded()
//            }
//        }
    }
    
    func blockChanges(block: (xxAppSettings) -> Void) async  {
        
    }
    
    func resetToDefaults() async {
        // ?
    }
    
    @discardableResult
    func saveIfNeeded() async -> Bool {
        return false
    }
    
    @discardableResult
    func save() async -> Bool {
        return false
    }
    
    var wasChanged : Bool {
        return _changes.count > 0
    }
    
    static var isLoaded : Bool {
        get {
            return Self._isLoaded
        }
        set {
            Self._isLoaded = newValue
        }
    }
    
    var isLoaded : Bool {
        return Self.isLoaded && !self.isLoading
    }
    
    
}

extension xxAppSettings /* loading */ {
    
    // MARK: Init / Load helpers
    static fileprivate func registerIffyCodables() {
        
        // Client:
        #if !VAPOR
        StringAnyDictionary.registerClass(PreferencesVC.PreferencesPage.self)
        #endif
        
        // Server:
        #if VAPOR
//          StringAnyDictionary.registerClass(?? .... )
        #endif
        
        // All Builds:
        StringAnyDictionary.registerType([String:String].self) // see UnkeyedEncodingContainerEx
    }
    
    fileprivate static func loadFromFile() -> xxAppSettings? {
        
        guard let path = pathToSettingsFile() else {
            dlog?.warning("pathToSettingsFile not found or nil!")
            return nil
        }
        
        guard _initingShared == false else {
            dlog?.warning(".shared Possible timed recursion! stack: " + Thread.callStackSymbols.descriptionLines)
            return nil
        }
        
        var result : xxAppSettings? = nil
        if true {
            _initingShared = true
            Self.registerIffyCodables()
            
            //  Find settings file in app folder (icloud?)
            let res : Result<xxAppSettings, Error> = Self.loadFromJSON(path)
            switch res {
            case .success(let success):
                result = success
            case .failure(let error):
                dlog?.warning("loadFromFile: Failed loading with error: \(error.description)")
            }
            _initingShared = false
        }

        return result
    }
}
*/
/*
    

    
    fileprivate func resetChangesRecord() {
        self._changes.removeAll(keepingCapacity: true)
    }
    
    // MARK: Public
    func noteChange(_ change:String, newValue:Any) {
        
        
        // "Other" are all settings properties that are distributed around the app as properties of other classes. They are still connected and saved into this settings file, under the "other" dictionary.
        if CodingKeys.isOther(key: change) {
            other[change] = newValue
        }
        
        // debounce
        // TimedEventFilter.shared.filterEvent(key: "AppSettings.changes", threshold: 0.3, accumulating: change) { changes in
        TimedEventFilter.shared.filterEvent(key: "AppSettings.changes", threshold: 0.2) {
            if self._changes.count > 0 {
                 dlog?.verbose("changed: \(self._changes.descriptionsJoined)")
                
                // Want to save all changes to settings into a seperate log?
                // Do it here! - use self._changes
                
                self.saveIfNeeded()
            }
        }
    }
    
    func blockChanges(block:(_ settingsProvider : AppSettingProvider)->Void) {
        self._isBlockChanges = true
        block(self)
        self._isBlockChanges = false
        self.saveIfNeeded()
    }
    
    func resetToDefaults() {
        self.global.existingUsernameAllowedTypes = UsernameType.allActive
        self.global.newUsernameAllowedTypes = UsernameType.allActive
        self.saveIfNeeded()
    }
    
    @discardableResult func saveIfNeeded()->Bool {
        if self.wasChanged && self.save() {
            return true
        }
        return false
    }
    
    @discardableResult
    func save()->Bool {
        if let path = Self.pathToSettingsFile() {
            let isDidSave = self.saveToJSON(path, prettyPrint: Debug.IS_DEBUG).isSuccess
            UserDefaults.standard.synchronize()
            dlog?.successOrFail(condition: isDidSave, "Saving settings")
            if isDidSave {
                if self._changes.count == 0 {
                    dlog?.note("Saved settings with NO CHANGES on record!")
                }
                self.resetChangesRecord()
            }
            
            return isDidSave
        }
        return false
    }
    
    // MARK: Singleton
    
                
                
                
                //  Find setings file in app folder (icloud?)
                let res = Self.loadFromJSON(path)

                switch res {
                case .success(let instance):
                    result = instance
                    Self._isLoaded = true
                    Self._initingShared = false
                    dlog?.success("loaded from: \(path.absoluteString) other: \(instance.other.keysArray.descriptionsJoined)")
                case .failure(let error):
                    let appErr = AppError(error: error)
                    dlog?.fail("Failed loading file, will create new instance. error:\(appErr) path:\(path.absoluteString)")
                     // Create new instance
                     result = AppSettings()
                     _ = result?.saveToJSON(path, prettyPrint: Debug.IS_DEBUG)
                }
            } else {
                dlog?.warning(".shared Possible timed recursion! stack: " + Thread.callStackSymbols.descriptionLines)
            }
        }
        
        _shared = result
        return result!
    }
    
    
    
    
}

*/
