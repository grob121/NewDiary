import Alamofire
import ObjectMapper

class WebService {
    static let shared = WebService()
    
    func postDiaryData(parameters: [String: Any], callback: @escaping (Swift.Result<User, Error>) -> Void) {        
        AF.request(
            Router.baseUrl + Router.Endpoints.users,
            method: .post,
            encoding: JSONEncoding.default)
            .responseString { response in
            switch response.result {
                case .success(let value):
                    guard let user = User(JSONString: value) else { return }
                    callback(.success(user))
                case .failure(let error):
                    callback(.failure(error))
            }
        }
    }
}
