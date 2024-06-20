@testable import BricksVapor
import XCTVapor
import Logging

fileprivate let dlog : Logger? = Logger(label:"UserTests") // ?.setting(verbose: false)

final class UserTests: XCTestCase {
    let app = Application(.testing)
    
    override func setUp() async throws {
        // defer { app.shutdown() }
        let _ = try AppConfigurator(app) {
            dlog?.info("App started: testing may begin")
        }
    }
    
    override func tearDown() async throws {
        app.shutdown()
        dlog?.info("App shutdown complete")
    }
    
    func testLogin() async throws {
        try app.test(.POST, AppConstants.API_PREFIX + "/user/login", beforeRequest: { req in
            // Authorization: Basic <credentials>
            // We then construct the credentials like this:
            // - The user's username and password are combined with a colon.
            // - The resulting string is base64 encoded.
            let credentials = "idorabin|123456".base64String()
            req.headers.add(name: "AUTHORIZATION", value: "BASIC: \(credentials)")
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            dlog?.info("RESPONSE.BODY: ===\n\(res.body)")
        })
    }
}
