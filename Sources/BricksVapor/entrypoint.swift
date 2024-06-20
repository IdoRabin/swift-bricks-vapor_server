import Vapor
import Dispatch
import Logging
import MNUtils

import NIO
import CNIOAtomics
import AsyncHTTPClient

// fileprivate let dlog : Logger? = Logger(label:"Entrypoint")// ?.setting(verbose: false)

/// This extension is temporary and can be removed once Vapor gets this support.
private extension Vapor.Application {
    static let baseExecutionQueue = DispatchQueue(label: "vapor.codes.entrypoint")
    
    func runFromAsyncMainEntrypoint() async throws {
        try await withCheckedThrowingContinuation { continuation in
            Vapor.Application.baseExecutionQueue.async { [self] in
                do {
                    try self.run()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

@main
enum Entrypoint {
    static func shutdownPoolIfNeeded() {
        // <EventLoopGroupConnectionPool<PostgresConnectionSource>: 0x60000237c800>
        // let pool = EventLoopGroupConnectionPool<PostgresConnectionSource
    }
    
    static func main() async throws {
        // dlog?.info("launch STARTED")
        
        self.shutdownPoolIfNeeded()
        
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = Application(env)
        defer { app.shutdown() }
        
        // Config
        let _ = try AppConfigurator(app) 
//        {
//            // after load and init is complete
//            dlog?.info("launch ENDED")
//        }
        
        try await app.runFromAsyncMainEntrypoint()
    }
}
