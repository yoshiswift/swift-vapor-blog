import Fluent

struct CreateBlog: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Blog.schema)
            .id()
            .field("title", .string, .required)
            .field("contents", .string)
            .field("user_id", .uuid, .references(User.schema, .id))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Blog.schema).delete()
    }
}