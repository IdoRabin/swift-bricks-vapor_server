import Fluent

extension User: AsyncMigration {
    
    func prepare(on database: FluentKit.Database) async throws {
        try await database.schema(User.schema)
            .field(.id, .uuid, .identifier(auto: false))
            .field("username", .string, .required)
            .field("display_name", .string)
            .field("avatar_url", .string)
            .field("password_hash", .string, .required)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .unique(on: "username")
            .create()
    }
    
    func revert(on database: FluentKit.Database) async throws {
        try await database.schema(User.schema).delete()
    }
}

