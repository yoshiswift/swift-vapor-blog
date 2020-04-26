import Vapor
import Fluent

final class User: Model, Content {
    static var schema: String = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Children(for: \.$user)
    var blogs: [Blog]
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(
        id: User.IDValue? = nil,
        name: String,
        username: String,
        passwordHash: String
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.passwordHash = passwordHash
    }
}

extension User {
    struct Public: Codable {
        var id: UUID?
        var name: String
        var username: String
        
        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
}
extension User.Public: Content {}
extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username)
    }
}
extension EventLoopFuture where Value: User {
    func convertToPublic() -> EventLoopFuture<User.Public> {
        return self.map { $0.convertToPublic() }
    }
}

extension User {
    struct Create: Content {
        var name: String
        var username: String
        var password: String
    }
}
