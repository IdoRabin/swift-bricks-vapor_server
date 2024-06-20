@testable import BricksVapor
import XCTVapor
import Logging

fileprivate let dlog : Logger? = Logger(label:"AppTests") // ?.setting(verbose: false)

final class AppTests: XCTestCase {
    func testAppLoadAndShutDown() async throws {
        let app = Application(.testing)
        // defer { app.shutdown() }
        let _ = try AppConfigurator(app) {
            dlog?.info("App startup done: Testing may begin")
            // app.connectionPool.shutdown()
            app.shutdown()
        }

//        try app.test(.GET, "hello", afterResponse: { res in
//            XCTAssertEqual(res.status, .ok)
//            XCTAssertEqual(res.body.string, "Hello, world!")
//        })
    }
}
