//
//  AppConfigurator.swift
//
//
// Created by Ido for bricks on 17/1/2024
//

import JWT
import Vapor
import Leaf
import Fluent
import FluentKit
import FluentPostgresDriver
import AsyncHTTPClient
import Logging

import MNUtils
import MNVaporUtils
import RRabac

// Global vars:
// fileprivate let debugMasterUser : User? = nil
fileprivate let dlog : Logger? = Logger(label:"AppConfigurator") // ?.setting(verbose: false)

class AppConfigurator {
    fileprivate static let INITIAL_DB_NAME = "?"
    
    // MARK: Private / filprivate methods that break down the configure process
    var debugUserAdded : Bool = false
    var debugUserBeingAdded : Bool = false
    var dbName : String = INITIAL_DB_NAME
    
    // MARK: Class lifecycle
    init() {
        dlog?.info("INIT -")
        let msg = "AppConfigurator was called with empty init!"
        // dlog?.raisePreconditionFailure()
        preconditionFailure(msg)
    }
    
    deinit {
        dlog?.verbose(symbol:.info, "DEINIT configurator. DB: [\(dbName)]")
    }
    
    var dbID : DatabaseID {
        guard self.dbName != Self.INITIAL_DB_NAME else {
            let msg = "dbID cannor be used before dbName is determined!"
            dlog?.warning(" \(msg) ")
            preconditionFailure(msg)
        }
        return DatabaseID(string: self.dbName)
    }
    
    // MARK: DB configuration
    private func determineDBNameIfNeeded(_ app: Application) {
        guard (dbName.count <= 3) else {
            return
        }
        
        var suffix = "debug"
        
        switch  app.environment.name {
        case "prod", "production":   suffix = "production"
        case "dev",  "development":  suffix = "staging"
        case "test", "testing":      suffix = "testing"
        default:                     suffix = "debug"
        }
        
        dbName = "bserver-\(suffix)"
    }
    
    
    fileprivate func allRRabacMigrations( app: Application)->[Migration] {
        guard let rrabac = app.middleware.getMiddleware(ofType: RRabacMiddleware.self) else {
            // throw MNError(.misc_security, )
            let msg = "allRRabacMigrations failed finding RRabacMiddleware!"
            preconditionFailure(msg)
        }
        
        // Find migrations from RRabac:
        return rrabac.allMigrations()
    }
    
    fileprivate func allDBMigrations( app: Application)->[Migration] {
        var result : [Migration] = [
            // Server env. and misc.
            User(),
            AccessToken(),
            
            // Project / Bricks models
//             BrickBasicInfo(),
//            Brick()
        ] // Project controller
        
        // RRabac
        //result.append(contentsOf: self.allRRabacMigrations(app: app))
        
        // MNVaporUtils
        // result.append(contentsOf: MNUtils.allMNVaporUtilsMigrations())
        
        return result
    }

    fileprivate func migrateDBInstance(_ app: Application, context:String) async throws {
        AppServer.shared.dbWillMigrate(db: app.db)
        
        let migrations : [Migration] = allDBMigrations(app:app)
        guard migrations.count > 0 else {
            dlog?.verbose(symbol:.info, "        📒 migrateDBInstance autoMigrate skipped: 0 tables to migrate from allDBMigrations!")
            return
        }
        
        // MIGARTIONS:
        do {
            let dbId = DatabaseID(string: dbName)
            app.migrations.add(migrations, to:dbId)
            
            // MNUser().prepare(on:app.db)
            
            // Migration!
            dlog?.verbose(symbol:.info, "        📒 migrateDBInstance autoMigrate START\ntables: \(migrations.map {$0.shortName })")
            try await app.autoMigrate().get()
            dlog?.verbose(symbol:.info, "        📒 migrateDBInstance autoMigrate END")
            
            /* TODO: uncomment
            // Will list table names after migrations:
            let migrationResult = try await app.validateMigration().get()
            dlog?.verbose(symbol:.info, "        📒 migrateDBInstance did validateMigration: \(migrationResult.description)")
            
            if migrationResult.isFailed, let err = migrationResult.errorValue {
                throw err
            }
            
             // Notify
             AppServer.shared.dbDidMigrate(db: app.db, error: migrationResult.errorValue)
             */
            
            // Notify
            AppServer.shared.dbDidMigrate(db: app.db, error: nil)
        } catch let error {
            if let psqlErr = error as? PSQLError {
                dlog?.verbose(symbol:.warning, "        📒 migrateDBInstance autoMigrate FAILED with psqlErr: \(psqlErr.fullDescription)")
                // psqlErr.backing.
                if let underlying = psqlErr.underlying as? PSQLError{
                    dlog?.verbose(symbol:.warning, "        📒 migrateDBInstance autoMigrate FAILED with underlying: \(underlying.fullDescription)")
                }
                // See configurator migration for memory session records..
//                if migration.name.contains("unknown context at") {
//                    self.database.logger.critical("The migration at \(migration.name) is in a private context. Either explicitly give it a name by adding the `var name: String` property or make the migration `internal` or `public` instead of `private`.")
//                    fatalError("Private migrations not allowed")
//                }
            } else {
                dlog?.verbose(symbol:.warning, "        📒 migrateDBInstance autoMigrate FAILED with error: \(error.description)")
            }
            
            AppServer.shared.dbDidMigrate(db: app.db, error: error)
            
            throw error
        }
    }
    
    /// TLS configutration for production SSL requirement
    /// - Returns:a TLSConfiguration instance, using some certificates.
    private func makeTlsConfiguration() throws -> TLSConfiguration {
        // TODO: Reinstate
        // .prefer(try .init(configuration: .clientDefault))
        // .makeServerConfiguration(certificateChain: [NIOSSLCertificateSource], privateKey: NIOSSLPrivateKeySource)
        var tlsConfiguration : TLSConfiguration = .makeClientConfiguration()
        if let certPath = Environment.get("DATABASE_SSL_CERT_PATH") {
            tlsConfiguration.trustRoots = NIOSSLTrustRoots.certificates(
                try NIOSSLCertificate.fromPEMFile(certPath)
            )
        }
        return tlsConfiguration
    }
    
    fileprivate func configureDBInstance(_ app: Application) async throws {
        
        AppServer.shared.dbWillInit("AppConfigurator.configureDBInstance")
        
        var tls : TLSConfiguration!
        if Debug.IS_DEBUG {
            tls = TLSConfiguration.makeClientConfiguration()
        } else {
            tls = try makeTlsConfiguration()
            throw AppError(code:.db_failed_init, reason:"TLSConfiguration for production requires SSL keys.")
        }
        
        // TODO: Obfuscate / save in keychain etc for username and password for the PG Connection string // TODO: Harden
        // https://www.raywenderlich.com/books/server-side-swift-with-vapor/v3.0/chapters/6-configuring-a-database#toc-chapter-009-anchor-003
        // This shows how to extract the password into Package.swift, omitting the hard-coded password/username inside the project.
        app.databases.use(.postgres(configuration: SQLPostgresConfiguration(
                hostname: Environment.get("DATABASE_HOST") ?? "localhost",
                port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber /* iana port = 5432 */ ,
                username: Environment.get("DATABASE_USERNAME") ?? "vapor",
                password: Environment.get("DATABASE_PASSWORD") ?? "vapor",
                database: Environment.get("DATABASE_NAME") ?? dbName,
                tls: .prefer(try .init(configuration: tls))) // Used when starting out: .init(configuration: .clientDefault)
        ), as: self.dbID /* DATABASE ID! */, isDefault:true)
        
        app.logger.info("migrateDB setting DB named: [\(dbName)] iana port: \(SQLPostgresConfiguration.ianaPortNumber)") // iana == 5432
        
        switch app.environment {
        case .production:
            app.passwords.use(.bcrypt(cost: 12)) // 12 is the default cost
        case .development, .testing:
            app.passwords.use(.plaintext)
        default: break
        }
        
        // Configure migrations
        var isShouldMigrate = true
        var dbMigrateContext = Debug.IS_DEBUG ? "migrating \(dbName)" : ""
        // Debug clear DB before start:
        if Debug.RESET_DB_ON_INIT {
            isShouldMigrate = debugConfigureDBResetOnInIt(app)
            if !isShouldMigrate {
                dbMigrateContext = "RESET_DB_ON_INIT"
            }
        }
        
        // Initialized
        // Notify:
        AppServer.shared.dbDidInit(db: app.db)
        
        // Migrate if needed
        if isShouldMigrate {
            try await self.migrateDBInstance(app, context: dbMigrateContext)
        } else {
            AppServer.shared.dbDidMigrate(db: app.db, error: AppError(code:.db_skipped_migration, reason: "DB migration deferred for this run [\(dbMigrateContext)]"))
        }
    }

//    private func asycConfigureDB(_ app: /* Vapor. */ Application) throws ->AppResult<String> {
//        let evloop = (AppServer.shared.vaporApplication?.eventLoopGroup.next())!
//        // evloop.makeFailedFuture(AppError(code:.db_failed_init, reason: "Unknown asycConfigureDB init error"))
//
//        let result : AppResult<String> = try evloop.submit {
//            return AppResult<String>.success("DB CONFIG SUCCESS \(Date.now.ISO8601Format())")
//        }.wait()
//
//        return result
//    }
    
    private func configureDB(_ app: /* Vapor. */ Application) throws {
        
        if dlog?.isVerboseActive == false { dlog?.info("configureDB START") }
        
        // JIC determine name:
        determineDBNameIfNeeded(app)
        
        dlog?.verbose(symbol: .info, "📒 configureDB START [\(self.dbName)]")
        let lock = MNThreadWaitLock()
        Task {[self] in
            AppServer.shared.dbName = self.dbName + " (Loading)"
            do {
                
                try await self.configureDBInstance(app)
                
                // Debug add / change DB info on init:
                try await self.configureDebugAddUserIfNeeded(app)
                 
                dlog?.verbose(symbol: .success, "    📒 configureDB success \(self.dbName)")
                
                // result = evloop.makeCompletedFuture(.success(Void()))
            } catch let error as NSError {
                // result = .failure(fromAppError: AppError(code: .db_failed_init, reasons: ["db configuration failed"], underlyingError: error))
                dlog?.warning("    📒 configureDB failed: [\(self.dbName)] error: \(error.description)")
                throw error
            }
            lock.signal()
        }
        
        lock.waitForSignal()
        dlog?.verbose("📒 configureDB END \(self.dbName)")
        
        if dlog?.isVerboseActive == false { dlog?.info("configureDB END") }
    }
    
    // MARK: Server configuration
    fileprivate func determineServerName(_ app: Application)->String {
        determineDBNameIfNeeded(app) // JIC
        return "\(dbName).\(Bundle.main.fullVersion)"
    }
    
    private func configureServer(_ app: /* Vapor. */ Application) throws {
        globalVaporApplication = app
        AppServer.shared.vaporApplication = app
        
        // Set AppServer as an observer of app LifecycleHandler protocol:
        app.lifecycle.use(AppServer.shared)
        
        // Content encoding:
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        ContentConfiguration.global.use(encoder: encoder, for: .json)
            
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        ContentConfiguration.global.use(decoder: decoder, for: .json)
        
        // ================= CONFIGURE SERVER ========================
        // Hostname.. port..
        app.http.server.configuration.hostname = "127.0.0.1"
        app.http.server.configuration.port = 8081
        app.http.server.configuration.backlog = 128 //  length for the queue of pending connections
        app.http.server.configuration.reuseAddress = true //  allows for reuse of local addresses when handling connections - when false raises many onnectionPool did not shut down correctly if an unknown timeout has not passed between server sessions (eps when debugging).
        app.http.server.configuration.responseCompression = .disabled // Enable / disable response compressing with gzip
        app.http.server.configuration.requestDecompression = .enabled(limit: .size(256000))  // Enable / disable request decompression for incoming requests encoded w/ gzip // Setting decompression size limits can help prevent maliciously compressed HTTP requests from using large amounts of memory. // size: Maximum decompressed size in bytes. ratio: Maximum decompressed size as ratio of compressed bytes. none: No size limits.
        app.http.server.configuration.supportPipelining = false
        
        // TODO: read about [.two] When not encrypted --- "Plaintext HTTP/2 (h2c) not yet supported."
        // Add to roadmap: when adding TLS middleware, add also http/2 support
        // see: https://stackoverflow.com/questions/46788904/why-do-web-browsers-not-support-h2c-http-2-without-tls
        app.http.server.configuration.supportVersions = [.one] // Supported http request versions one | two
        
        // Server name:
        // This will be the "Server" header on outgoing HTTP responses
         app.http.server.configuration.serverName = AppConstants.APP_NAME + "; v" + Bundle.main.fullVersion + "; vapor 4.0;"

        // = = = = = = Middlewares Config = = = = = = = = = = = = = = = = =
        // NOTE: Order matters!
        self.ConfigSessionsMiddleware() // first!
        try self.configRedirectMiddleware() // second
        self.configRoutingHistoryMiddleware() // before ErrorMiddleWare / AppErrorMiddleware
        self.configRateLimitMiddleware()
        self.configAppErrorMiddleware()
        self.configRRabacMiddleware()
        self.configFileMiddleware() // Uncomment to serve files from /Public folder
        

        // Increases the streaming body collection limit to 500kb
        // app.routes.defaultMaxBodySize = "500kb"
        
        // JWT: Add HMAC with SHA-256 signer key
        app.jwt.signers.use(.hs256(key: AppConstants.ACCESS_TOKEN_JWT_KEY))
        app.routes.caseInsensitive = true
        
        /*
        app.jwt.apple.applicationIdentifier = "..."
        app.get("apple") { req -> EventLoopFuture<HTTPStatus> in
            req.jwt.apple.verify().map { token in
                print(token) // AppleIdentityToken
                return .ok
            }
        }

        app.jwt.google.applicationIdentifier = "..."
        app.jwt.google.gSuiteDomainName = "..."
        app.get("google") { req -> EventLoopFuture<HTTPStatus> in
            req.jwt.google.verify().map { token in
                print(token) // GoogleIdentityToken
                return .ok
            }
        }

        app.jwt.microsoft.applicationIdentifier = "..."
        app.get("microsoft") { req -> EventLoopFuture<HTTPStatus> in
            req.jwt.microsoft.verify().map { token in
                print(token) // MicrosoftIdentityToken
                return .ok
            }
        }
         */
    }
    
    // MARK: Debug / Mockup
    fileprivate func configureDebugAddUserIfNeeded(_ app: Application, depth:Int = 0) async throws {
        
        guard Debug.IS_DEBUG, self.debugUserAdded == false, self.debugUserBeingAdded == false else {
            return
        }
        guard depth < 5 else {
            dlog?.warning("configureDebugAddUserIfNeeded waited / recursion depth >= 5!")
            return
        }
        
        // Timed loop!
        guard self.debugUserBeingAdded == false else {
            DispatchQueue.main.asyncAfter(delayFromNow: 0.2) {[self] in
                Task {[self] in
                    //'async' call in a function that does not support concurrency
                    try await self.configureDebugAddUserIfNeeded(app, depth:depth + 1)
                }
            }
            return
        }
        self.debugUserBeingAdded = true
        
        /*
        func debugSetMasterPermissionsIfNeeded(_ user : User) {
            if let id = user.id {
                DispatchQueue.global().async {
                    let cache = UserMgr.shared.permissions
                    let permissions = UserMgr.UserPermissions.allowedActions(Set(UserAction.all.simplified).compactizeIfPossible())
                    cache[id] = permissions
                    cache.saveIfNeeded()
                }
            }
        }
         */
    }

    fileprivate func debugConfigureDBResetOnInIt(_ app: Application)->Bool {
        var isShouldMigrate = false
        let lock = MNThreadWaitLock()
        dlog?.note("debugConfigureDBResetOnInt Debug.RESET_DB_ON_INIT db [\(dbName)] will drop all tables!")
        DBActions.postgres.dropAllTables(db: app.db, ignoreFluentTables: false) { dropAllResult in
            switch dropAllResult {
            case .failure(let error):
                dlog?.fail("debugConfigureDBResetOnInIt   [\(self.dbName)] drop all tables failed with error: \(error.localizedDescription)")
                //app.logger.notice("  db [\(dbName)] drop all tables failed with error: \(error.localizedDescription)")
                
            case .success(let reason):
                dlog?.success("debugConfigureDBResetOnInIt    [\(self.dbName)] drop all tables success: \(reason)")
                //app.logger.info("  db [\(dbName)] drop all tables success: \(reason)")
                isShouldMigrate = true
            }
            lock.signal()
        }
        lock.waitForSignal()
        return isShouldMigrate
    }

    
    // MARK: lifecycle
    init(_ app: /* Vapor. */ Application, whenDone:(() throws ->Void)? = nil) throws {
        // Some troubleshooting cmds:
        /*
         // GET CUR VERSION: postgres -V
         // RESTART UNDER BREW: brew services restart postgresql
         // LIST CUR POSTGRES STATUS (should appear): brew services list
         */
        do {
            try configureServer(app)
            try configureDB(app)
            
            AppServer.shared.dbName = self.dbName
            
            // // TODO: uncomment:  AppServer.shared.users.db = app.db
            // // TODO: AppServer.shared.permissions?.db = app.db
            
            // Configuation of Leaf must take place after app.autoMigrate().wait() (which is in the DB init inside configureDB)
            app.views.use(.leaf)

        } catch let error {
            dlog?.warning("error \(error.description)")
        }
        
        
        // Exec "when done" block
        try whenDone?()
    }
}
