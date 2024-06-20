import Fluent
import MNVaporUtils

extension AccessToken: AsyncMigration {
    func prepare(on database: Database) async throws {
        
        // Create enums in DB
        let dbSessionSourceEnumType = try await database.asyncCreateOrGetCaseIterableEnumType(anEnumType: SessionSource.self)
        
        // Create Model in DB
        try await database.schema(AccessToken.schema)
            .field(.id, .uuid, .identifier(auto: false))
            .field("user_id", .uuid, .references("users", "id"))
            .field("value", .string, .required)
            .field("source", dbSessionSourceEnumType, .required)
            .field("created_at", .datetime, .required)
            .field("expires_at", .datetime)
            .unique(on: "value")
            .create()
    }
    
    func revert(on database: Database) async throws {
        // Remove Model from DB
        try await database.schema(AccessToken.schema).delete()
        
        // Remove Enums from DB
        try await database.deleteEnumType(anEnumType: SessionSource.self)
    }
}
