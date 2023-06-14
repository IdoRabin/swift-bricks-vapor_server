//
//  AppVaporLifecycleHandler.swift
//  
//
//  Created by Ido on 13/10/2022.
//

import Foundation

#if NIO || VAPOR

import Vapor
import NIO

import DSLogger
import MNUtils
import MNVaporUtils

fileprivate let dlog : DSLogger? = DLog.forClass("App")

enum AppServerEnvironment : Codable, Equatable, CustomStringConvertible {
    case production
    case development
    case testing
    case custom(String)
    
    static var staging = AppServerEnvironment.development
    static var allStatic : [AppServerEnvironment] = [.production, .development, .testing]
    
    var description: String {
        var result = "Unknown?"
        switch self {
        case .production:   result = "production"
        case .development:  result = "development"
        case .testing:      result = "testing"
        case .custom(let string): result = string
        }
        return result
    }
    
    var intValue : Int {
        var result = 0
        switch self {
        case .production:   result = 0
        case .development:  result = 1
        case .testing:      result = 2
        case .custom(let string): result = max(abs(string.hashValue), 4)
        }
        return result
    }
}

weak var globalVaporApplication : Application? = nil

// Wrapper for Vapor Application (cannot subclass or extend since it is final)
class AppServer : LifecycleHandler {
    
    static let INITIAL_DB_NAME = "?"
    
    // UserMgr.shared.db = app.db // set weak db in UserMgr
    // MARK: members
    weak var settings = AppSettings.shared
    weak var vaporApplication : Application? = nil
    weak var permissions : AppPermissionMiddleware? = nil
    // UNCOMMENT var users : UserMgr = UserMgr()
    var routeMgr : MNRoutes
    
    // MARK: flags and names members
    var dbName : String = AppServer.INITIAL_DB_NAME
    var isBooting : Bool = false
    var isDBLoaded : Bool = false
    
    static private (set) var isInitializing : Bool = true
    
    // READ-ONLY! increment should be made to settings?.stats.launchCount
    var launchCount : Int {
        get {
            return self.settings?.stats.launchCount ?? 1
        }
    }
    
    // READ-ONLY! increment should be made to settings?.stats.launchCount
    var launchCountHexString : String {
        get {
            // Foundation:
            return self.launchCount.toHex(uppercase: false)
        }
    }
    
    // MARK: Computed props
    var environment : AppServerEnvironment {
        var result : AppServerEnvironment = .custom("Unknown")
        
        guard let vaporApplication = vaporApplication ?? globalVaporApplication else {
            return result
        }
        
        switch vaporApplication.environment.name {
        case "prod", "production":   result = .production
        case "dev",  "development":  result = .development
        case "test", "testing":      result = .testing
        default:
            break
        }
        return result
    }
    
    // MARK: Singleton
    public static let shared = AppServer()
    private init() {
        Self.isInitializing = true
        isBooting = true
        routeMgr = MNRoutes()
        // Rabac.shared.setupIfNeeded()
        Self.isInitializing = false
    }
    
    var isDBConfigured : Bool {
        return (self.dbName != Self.INITIAL_DB_NAME) && !(self.dbName.contains("loading", isCaseSensitive: false)) && (self.isDBLoaded == true)
    }
    
    // MARK: Public
    public func manualShutdown(user:User) {
        // user.
//        guard UserMgr.shared.isAllowed(for: user, to: .allActions, on: nil, during: nil).isSuccess else {
//            dlog?.warning("manualShutdown failed: user [\(user.description)] doesn't have permission to manually shutdown the server!")
//            return
//        }
        
        guard let app = vaporApplication ?? globalVaporApplication else {
            dlog?.note("manualShutdown failed: serverApp is nil!")
            return
        }
        
        self.settings?.saveIfNeeded()
        
        // TODO: This is a security volnerability here, since theoretically, someone can shutdown the server through privilege ascention
        app.shutdown()
        
        // Wait for the server to shutdown.
        do {
            try app.server.onShutdown.wait()
        } catch let error {
            dlog?.warning("manualShutdown .onShutdown wait failed with error: \(error.description)")
        }
    }
    
    // MARK: LifecycleHandler
    func willBoot(_ application: Vapor.Application) throws {
        try self.permissions?.willBoot(application)
        dlog?.info("> Vapor app will Boot Nr.# \(self.launchCountHexString)")
    }
    
    func didBoot(_ application: Vapor.Application) throws {
        
        // Wait for isDBLoaded to be true:
        if let perm = AppServer.shared.permissions {
            // Boot - register perissions for all routes.
            try perm.boot(application) // globsl function for registering permissions
        } else {
            dlog?.note("didBoot() AppPermissionMiddleware was not set in time for AppServer to call its boot!")
        }
        
        // Change stats on launch
        settings?.blockChanges(block: { settings in
            settings.stats.launchCount = self.launchCount
            settings.stats.lastLaunchDate = Date();
        })
        
        isBooting = false
        
        dlog?.success("Vapor app did Boot: [\(Bundle.main.bundleName ?? "BServer") v\(Bundle.main.fullVersion) ] run Nr.#\(self.launchCountHexString) -[\(self.environment)]-")
         
        // NOTE: Call secureRoutesAfterBoot only after changing the isBooting flag to false:
        self.routeMgr.secureRoutesAfterBoot(application)

        //        Rabac.shared.didBoot()
        try self.permissions?.didBoot(application)
    }
    
    func shutdown(_ application: Vapor.Application) {
        
        /* terminal:
            sudo lsof -i :8081
            >>> (see list of processes holding the port)
            sudo kill -9 {PID}
        */
        // OR
        /*
            lsof -i :8080 -sTCP:LISTEN | awk 'NR > 1 {print $2}' | xargs kill -15
         */
        // OR
        /*
            usage: pkill [-signal] [-ILfilnovx] [-F pidfile] [-G gid]
                         [-P ppid] [-U uid] [-g pgrp] [-t tty] [-u euid]
                         pattern ..
            pkill "BricksServer"
         */
        
        dlog?.info("> Vapor app will shutdown: [\(Bundle.main.bundleName ?? "BServer") v\(Bundle.main.fullVersion)] run Nr.#\(self.launchCountHexString)")
        
        // Close postgres gracefully:
        DBActions.postgres.shutdown(db:application.db) // Custom events
        application.storage.shutdown() // Hard coded in Vapor kit.
    }
}

extension AppServer {
    
    static func devStringOrNil(_ str:String)->String? {
        guard AppServer.shared.environment != .production else {
            return nil
        }
        return str
    }
    
    static func devStringOrEmpty(_ str:String)->String {
        guard AppServer.shared.environment != .production else {
            return ""
        }
        return str
    }
}

extension AppServer {
    
    private static func nextEventLoop() throws ->EventLoop {
        let vaporApplication = Self.isInitializing ? globalVaporApplication : AppServer.shared.vaporApplication
        guard let vaporApplication = vaporApplication else {
            dlog?.warning("AppServer.nextEventLoop failed to find vaporApplication or an eventLoop!")
            throw AppError(code:.misc_failed_creating, reason: "AppServer.nextEventLoop failed to find vaporApplication or an eventLoop!")
        }
        return vaporApplication.eventLoopGroup.next()
    }
    
    @discardableResult
    static func scheduleTask<T>(deadline: NIODeadline, _ task: @escaping () throws -> T)->Scheduled<T> {
        do {
            return try self.nextEventLoop().scheduleTask(deadline: deadline, task)
        } catch let error {
            do {
                let promise : EventLoopPromise<T> = try self.nextEventLoop().makePromise()
                let sched = Scheduled(promise: promise) {
                    dlog?.warning("scheduleTask<T>(deadline: was canceled!")
                }
                promise.fail(error)
                return sched
            } catch {
                dlog?.warning("scheduleTask<T>(deadline:) failed creaing a schedulaed task!")
            }
        }
        
        preconditionFailure("scheduleTask<T>(deadline:) failed creaing a schedulaed task!")
    }
    
    @discardableResult
    static func scheduleTask<T>(delayFromNow: TimeInterval, _ task: @escaping () throws -> T)->Scheduled<T> {
        let deadline = NIODeadline.delayFromNow(delayFromNow)
        return self.scheduleTask(deadline: deadline, task)
    }
}

#endif
