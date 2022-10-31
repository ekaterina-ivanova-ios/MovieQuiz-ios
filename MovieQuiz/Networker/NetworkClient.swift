import Foundation

protocol NetworkRouting {
    func fetch(requestModel: RequestModel, handler: @escaping (Result<Data, NetworkError>) -> Void)
}

struct NetworkClient: NetworkRouting {
    
    func fetch(requestModel: RequestModel, handler: @escaping (Result<Data, NetworkError>) -> Void) {
        guard let url = URL(string: requestModel.url) else {
            handler(.failure(.invalidUrl))
            return
        }
        
        var request = URLRequest(url: url,
                                cachePolicy: .useProtocolCachePolicy,
                                timeoutInterval: 60*60)
        request.httpMethod = requestModel.httpMethod.rawValue

        let session = URLSession.shared
        session.dataTask(with: request) { data, _, error in
            if let data = data {
                    handler(.success(data))
            } else {
                    handler(.failure(.networkTaskError))
            }
        }.resume()
    }
}

enum NetworkError: Error {
    case codeError, invalidUrl, networkTaskError, test
}
