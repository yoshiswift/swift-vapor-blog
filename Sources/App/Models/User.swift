import Vapor
import Fluent

final class User: Model, Content {
    static var schema: String = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: .name)
    var name: String
    
    @Field(key: .username)
    var username: String
    
    @Field(key: .passwordHash)
    var passwordHash: String
    
    @Children(for: \.$user)
    var blogs: [Blog]
    
    @Timestamp(key: .createdAt, on: .create)
    var createdAt: Date?
    
    @Timestamp(key: .updatedAt, on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: .deletedAt, on: .delete)
    var deletedAt: Date?
    
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

extension User: ModelAuthenticatable {
    static var usernameKey: KeyPath<User, Field<String>> {
        return  \.$username
    }
    
    static var passwordHashKey: KeyPath<User, Field<String>> {
        return \.$passwordHash
    }
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64,
            userID: self.requireID()
        )
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(8...))
    }
}

struct UserCredentialsAuthenticator: CredentialsAuthenticator {
    struct Input: Content {
        let username: String
        let password: String
    }
    
    typealias Credentials = Input
    
    func authenticate(credentials: Credentials, for req: Request) -> EventLoopFuture<Void> {
        User.query(on: req.db)
            .filter(\.$username == credentials.username)
            .first()
            .unwrap(or: Abort(.unauthorized))
            .flatMap { user in
                req.password.async.verify(credentials.password, created: user.passwordHash).map { pass in
                    if pass {
                        req.auth.login(user)
                    }
                }
        }
    }
}

extension User: SessionAuthenticatable {
    typealias SessionID = String
    var sessionID: String {
        return self.username
    }
}
struct UserSessionAuthenticator: SessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: User.SessionID, for request: Request) -> EventLoopFuture<Void> {
        User
            .query(on: request.db)
            .filter(\.$username == sessionID)
            .first()
            .map {
                if let user = $0 {
                    request.auth.login(user)
                }
        }
    }
}
