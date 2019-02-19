import FluentSQLite
import Vapor
import Authentication

enum Color: Int, Codable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
}

struct Dance: Codable {
    var title: String
    var body: String
}

struct DanceFolder: Codable {
    var title: String
    var color: Color
    var dances: [Dance]
}

final class User: SQLiteModel {
    var id: Int?
    var email: String
    var password: String
    
    var folders: [DanceFolder] = []

    init(id: Int? = nil, email: String, password: String) {
        self.id = id
        self.email = email
        self.password = password
    }
}
extension User: Content {}
extension User: Migration {}
extension User: PasswordAuthenticatable {
    static var usernameKey: WritableKeyPath<User, String> {
        return \User.email
    }
    static var passwordKey: WritableKeyPath<User, String> {
        return \User.password
    }
}
extension User: SessionAuthenticatable {}
