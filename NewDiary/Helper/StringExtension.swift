import Foundation

extension String {
    func localize() -> String {
        return NSLocalizedString(self, comment: "")
    }
}

struct Router {
    static let baseUrl = "https://reqres.in/"
    
    struct Endpoints {
        static let users = "api/users"
    }
}
