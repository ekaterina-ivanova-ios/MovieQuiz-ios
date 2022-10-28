
import Foundation

protocol MoviesLoading {
    func loadMovies(handler: @escaping (Result<MostPopularMovies, NetworkError>) -> Void)
}

struct MoviesLoader: MoviesLoading {
    
    let networkClient = NetworkClient()
    
    func loadMovies(handler: @escaping (Result<MostPopularMovies, NetworkError>) -> Void) {
        let httpMethod = HttpMethod.get
        let url = "https://imdb-api.com/en/API/Top250Movies/k_z47oa8aj"
        //let url = ""
        let requestModel = RequestModel(httpMethod: httpMethod, url: url)
        
        networkClient.fetch(requestModel: requestModel) {result in
            switch result {
            case .success(let data):
                guard let decodedResponse = try? JSONDecoder().decode(MostPopularMovies.self, from: data) else {
                    handler(.failure(.codeError))
                    return
                }
    
                handler(.success(decodedResponse))
                
            case .failure(let error):
                handler(.failure(error))
            }
        }
    }
}

enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

struct RequestModel {
    let httpMethod: HttpMethod
    let url: String
}
