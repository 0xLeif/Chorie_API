import Vapor
import FluentSQL
import Crypto
import Authentication

class UserController: RouteCollection {
    func boot(router: Router) throws {
        router.post("register", use: register)
        
        let authSessionRouter = router.grouped(User.authSessionsMiddleware())
        authSessionRouter.post("login", use: login)
        
        let protectedRouter = authSessionRouter.grouped(RedirectMiddleware<User>(path: "/login"))
        protectedRouter.get("profile", use: profile)
        
        router.get("logout", use: logout)
    }
    
    func register(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.content.decode(User.self).flatMap { user in
            
            return User.query(on: req).filter(\User.email == user.email).first().flatMap { result in
                if let _ = result {
                    return Future.map(on: req) {
                        return HTTPStatus.badRequest
                    }
                }
                
                user.password = try BCryptDigest().hash(user.password)
                
                return user.save(on: req).map { _ in
                    return HTTPStatus.accepted
                }
            }
        }
    }
    
    func login(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.content.decode(User.self).flatMap { user in
            return User.authenticate(
                username: user.email,
                password: user.password,
                using: BCryptDigest(),
                on: req
                ).map { user in
                    guard let user = user else {
                        return HTTPStatus.badRequest
                    }
                    
                    try req.authenticateSession(user)
                    return HTTPStatus.accepted
            }
        }
    }
    
    func profile(_ req: Request) throws -> String {
        let user = try req.requireAuthenticated(User.self)
        return "You're viewing \(user.email) profile."
    }
    
    func logout(_ req: Request) throws -> Future<HTTPStatus> {
        try req.unauthenticateSession(User.self)
        return Future.map(on: req) { return HTTPStatus.noContent }
    }
}
