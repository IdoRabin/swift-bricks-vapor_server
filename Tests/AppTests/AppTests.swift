@testable import BricksServer
import XCTVapor
import DSLogger

fileprivate let dlog : DSLogger? = DLog.forClass("AppTests")?.setting(verbose: false)

final class AppTests: XCTestCase {
    
    func testStringBase64Encodings()  {
        let dict = [
            "user_id" : "5DA7C566-B30A-4D51-BA1A-0E75244A67F2",
            "expiration_date" : "2023-11-30T15:01:21Z"
        ]
        let orig = dict.toURLQueryString(encoding: .normal, isShouldPercentEscape: false)
        let base64 = orig.toBase64()
        let fromBase64 = base64.fromBase64()
        let exploded = base64.explodeBase64IfPossible()
        
        dlog?.info("[TED] orig: " + orig)
        dlog?.info("[TED] base64: " + base64)
        dlog?.info("[TED] fromBase64: " + fromBase64.descOrNil)
        dlog?.info("[TED] exploded: " + exploded.descOrNil)
        
        XCTAssertEqual(orig, fromBase64)
        XCTAssertEqual(dict, exploded)
    }
    
    func testHelloWorld() async throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try await configure(app)

        try app.test(.GET, "hello", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "Hello, world!")
        })
    }
}
