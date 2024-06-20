import Vapor
import Fluent
import MNUtils
import MNVaporUtils
import JWT
import Logging

fileprivate let dlog : Logger? = Logger(label:"AccessToken")

final class AccessToken: Model, Codable {
    // MARK: Types
    struct Public : AppEncodableVaporResponse, AsyncResponseEncodable {
        let expiresAt: Date
        let token : String
    }
    
    // MARK: Const
    // MARK: Static
    private static var _cookieName : String = ""
    static var cookieName : String {
        get {
            if _cookieName == "" {
                _cookieName = "X-\(AppConstants.APP_NAME.replacingOccurrences(of: .whitespaces, with: "-"))-BTOK-Cookie"
            }
            return _cookieName
        }
    }
    
    fileprivate static var expiredTokenContent : String {
        get {
            return "-expired-"
        }
    }
    
    // MARK: Model
    static let schema = "access_tokens"
    
    // MARK: Properties / members
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "value")
    var value: String
    
    @Field(key: "source")
    var source: SessionSource
    
    @Field(key: "expires_at")
    var expiresAt: Date
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    var remainingTimeInterval : TimeInterval {
        guard self.expiresAt.isInTheFuture else {
            return 0
        }
        
        return abs(self.expiresAt.timeIntervalSinceNow)
    }
    
    var remainingDurationSeconds : Int {
        guard self.expiresAt.isInTheFuture else {
            return 0
        }
        
        return Int(self.remainingTimeInterval)
    }
    
    // MARK: Lifecycle
    init() {
    }
    
    init(id: UUID? = UUID(), userId: User.IDValue, token: String,
         source: SessionSource, expiresAt: Date) {
        self.id = id
        self.$user.id = userId
        self.value = token
        self.source = source
        self.expiresAt = expiresAt
    }
    
    convenience init?(fromBearerToken token:String, for req:Request) async {
        do {
            let decoded = try req.jwt.verify(token, as: Self.self)
            if let userId = decoded.$user.$id.value {
                self.init(id: decoded.id, userId: userId, token: decoded.value, source: decoded.source, expiresAt: decoded.expiresAt)
                _ = try await self.$user.get(on: req.db)
                dlog?.success("AccessToken.init(fromBearerToken:req:) decoded: \(decoded)")
                
                // SUCCESS!
                return
            } else {
                dlog?.fail("AccessToken.init(fromBearerToken:req:) FAILED: user id missing.")
            }
        } catch let error {
            dlog?.fail("AccessToken.init(fromBearerToken:req:) FAILED: jwt verify failed! error: \(error.description)")
        }
        
        // FAILED
        return nil
    }
    
    convenience init?(fromRequestBTOKCookie req:Request?) async {
        let isLogs = req?.route?.mnRouteInfo?.requiredAuth.contains(.userToken) ?? false
        let logr = isLogs ? dlog : nil
        
        // Cooie exists in the request
        guard let req = req, let cookie = req.cookies[Self.cookieName], cookie.string.count > 0 else {
            logr?.note("AccessToken.init(fromCookie:) FAILED: BTOK cookie is missing, empty or nil!")
            return nil
        }
        
        // Cookie is not expired
        if let expiration = cookie.expires, expiration.isInThePast {
            logr?.note("AccessToken.init(fromCookie:) FAILED: BTOK cookie is expired!")
            return nil
        }
        
        await self.init(fromBearerToken: cookie.string, for: req)
    }
    
    // MARK: Private
    
    // MARK: Public
    static func newExpirationDate(user:User) throws ->Date {
        let calendar = Calendar(identifier: .gregorian)
        let expiryDate = calendar.date(byAdding: .month, value: 3, to: Date.now)
        guard let expiryDate = expiryDate else {
            throw MNError(code:.http_stt_internalServerError, reason: "AccessToken expiration failure")
        }
        return expiryDate
    }
    
    func asPublic() throws -> Public {
        return Public(expiresAt: self.expiresAt, token: value)
    }
    
    func asBearerToken(extraInfo:Bool, for req:Request) throws ->String {
        return try req.jwt.sign(self)
    }
    
    func asCookie(for req:Request) throws ->HTTPCookies.Value {
        var bearerToken = try self.asBearerToken(extraInfo: Debug.IS_DEBUG, for: req)
        if self.expiresAt.isInThePast {
            bearerToken = Self.expiredTokenContent
        }
        let cookie = HTTPCookies.Value(
            string: bearerToken,
            expires: self.expiresAt,
            maxAge:  self.remainingDurationSeconds, // the time in seconds
            domain: req.application.http.server.configuration.hostname,
            isSecure: false, // TODO: Detect if TLS settings of server are active and set secure to true
            isHTTPOnly: !Debug.IS_DEBUG,
            sameSite: .lax) // HTTPCookies.SameSitePolicy.strict
        // Note this is the bearer token cookie name, not the session cookie
        
        // MDN says MAX cookie length = 4096 bytes
        // While it may appear to be a strange joke, browsers do impose cookie limits. A browser should be able to accept at least 300 cookies with a maximum size of 4096 bytes, as stipulated by RFC 2109 (#6.3), RFC 2965 (#5.3), and RFC 6265. (including all parameters, so not just the value itself)
        if cookie.string.count > 4096 - Self.cookieName.count {
            dlog?.warning("Created cookie is too long for ")
        }
        
        return cookie
    }
    
    static func unknownExpiredCookie(for req:Request)->HTTPCookies.Value {
        let cookie = HTTPCookies.Value(
            string: Self.expiredTokenContent,
            expires: Date(timeIntervalSinceNow: -5.0 /* JIC */), // Expired
            maxAge:  0, // the time in seconds
            domain: req.application.http.server.configuration.hostname,
            isSecure: false, // TODO: Detect if TLS settings of server are active and set secure to true
            isHTTPOnly: !Debug.IS_DEBUG,
            sameSite: .lax) // HTTPCookies.SameSitePolicy.strict
        return cookie
    }
    
    /// Expire this token
    /// - Parameters:
    ///   - source: termination source
    ///   - expirationDate: termination date, defaults to Date.now
    ///   - db: database to save in
    func expire(source: SessionTerminationSource, expirationDate:Date = Date.now, db:Database) async throws {
        self.expiresAt = expirationDate
        try await self.save(on: db)
    }
    
    
}

extension AccessToken: ModelTokenAuthenticatable {
    static let valueKey = \AccessToken.$value
    static let userKey = \AccessToken.$user
    
    var isValid: Bool {
        return expiresAt.isInTheFuture(safetyMargin: 5 /* Seconds */)
    }
}

extension AccessToken: JWTPayload {
    func verify(using signer: JWTKit.JWTSigner) throws {
        guard self.isValid else {
            dlog?.fail("AccessToken is invalid or expired!!")
            throw MNError(code: .http_stt_unauthorized, reason: "Invalid token")
        }
        
        dlog?.success("AccessToken authenticated!")
    }
}

