import Fluent
import Vapor
import Logging

fileprivate let dlog : Logger? = Logger(label:"User")


final class User: Model, Content {
    // MARK: Model protocol
    static let schema = "users"
    
    // MARK: Types
    struct Public: AppEncodableVaporResponse, AsyncResponseEncodable {
        // let username: String
        let displayName: String
        let avatarURL : URL?
        let id: UUID
        let createdAt: Date?
        let updatedAt: Date?
    }
    
    // MARK: Const
    // MARK: Static
    // MARK: Properties / members
    @ID(key: .id)
    var id: UUID?
    
     @Field(key: "username")
     var username: String
    
    @Field(key: "display_name")
    var displayName: String
    
    @Field(key: "avatar_url")
    var avatarURLStr: String?
    
    // Postgres cannot code/decode to URL
    var avatarURL: URL? {
        get {
            guard let str = avatarURLStr else {
                return nil
            }
            return URL(string: str)
        }
    }
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    // MARK: Private
    // MARK: Public
    
    // MARK: Lifecycle
    init() { }
    
    init(id: UUID? = UUID(), displayName: String, avatarURL:URL?) {
        self.id = id
        self.displayName = displayName
        self.avatarURLStr = avatarURL?.absoluteString
    }
    
    init(id: UUID? = UUID(), username: String, displayName: String? = nil, passwordHash: String, avatarURL:URL?) {
        self.id = id
        self.username = username
        self.displayName = displayName ?? username
        self.passwordHash = passwordHash
        self.avatarURLStr = avatarURL?.absoluteString
    }
}

extension User {
    static func create(from userSignup: UserSignup) throws -> User {
        return User(username: userSignup.username,
                    passwordHash: try Bcrypt.hash(userSignup.password),
                    avatarURL: userSignup.avatarURL != nil ?  URL(string: userSignup.avatarURL!) : nil)
    }
    
    func createToken(source: SessionSource) throws -> AccessToken {
        let calendar = Calendar(identifier: .gregorian)
        let expiryDate = try AccessToken.newExpirationDate(user: self)
        return try AccessToken(userId: requireID(),
                               token: [UInt8].random(count: 16).base64, 
                               source: source,
                               expiresAt: expiryDate)
    }
    
    func expireToken(token:AccessToken, source: SessionTerminationSource, expirationDate:Date = Date.now, db:Database) async throws -> AccessToken? {
        token.expiresAt = expirationDate
        try await token.save(on: db)
        return token
    }
    
    func expireToken(source: SessionTerminationSource, expirationDate:Date = Date.now, db:Database) async throws -> AccessToken? {
        guard self.id != nil else {
            dlog?.note("User.expireToken self.id is nil!")
            return nil
        }
        
        let token = try await AccessToken.query(on: db)
            .filter(\.$user.$id == self.id!)
            .first()
        guard let token else {
            dlog?.note("User.expireToken failed finding token for user \(self.username) \(self.id.descOrNil)")
            return nil
        }
        
        try await token.expire(source: source, expirationDate: expirationDate, db: db)
        return token
    }
    
    func asPublic() throws -> Public {
        Public(// username: username,
               displayName: displayName,
               avatarURL: avatarURL,
               id: try requireID(),
               createdAt: createdAt,
               updatedAt: updatedAt)
    }
}
