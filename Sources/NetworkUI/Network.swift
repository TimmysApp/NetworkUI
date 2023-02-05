import Foundation
import Combine

public actor Network {
    internal static var configurations: NetworkConfigurations!
    public static func set(configurations: NetworkConfigurations) {
        Network.configurations = configurations
    }
//MARK: - Request Builder
    internal static func requestBuilder<T: EndPoint>(endPoint: T) throws -> URLRequest {
        var requestURL: URL?
        if let baseURL = endPoint.baseURL {
            let reproccessed = endPoint.route.reproccessed(with: endPoint.reprocess(url: endPoint.route.applied(to: baseURL)))
            requestURL = reproccessed
        }else if let baseURL = configurations.baseURL {
            let reproccessed = endPoint.route.reproccessed(with: configurations.reprocess(url: endPoint.route.applied(to: baseURL)))
            requestURL = reproccessed
        }else {
            throw NetworkError(title: "Error", body: "No Base URL found!")
        }
        guard let requestURL else {
            throw NetworkError(title: "Error", body: "The constructed URL is invalid!")
        }
        var request = URLRequest(url: requestURL, timeoutInterval:  configurations.timeoutInterval)
        request.httpMethod = endPoint.method.rawValue
        request.cachePolicy = configurations.cachePolicy
        request.configure(headers: endPoint.headers)
        if let data = endPoint.body?.data {
            request.httpBody = data
        }
        return request
    }
//MARK: - Result Builder
    internal static func resultBuilder<T: EndPoint, Model: Decodable, ErrorModel: Error & Decodable>(call: NetworkCall<Model, ErrorModel, T>, request: URLRequest, data: Data) async throws -> Model {
        print("------Begin Request------")
        print(request.cURL(pretty: true))
        print("------End Request------")
        print("------Begin Response------")
        print(data.prettyPrinted)
        print("------End Response------")
        if call.handler.withLoading {
            await NetworkData.shared.set(loading: false)
        }
        if call.errorModel != nil {
            guard let model = try? configurations.decoder.decode(Model.self, from: data) else {
                let errorModel = try configurations.decoder.decode(ErrorModel.self, from: data)
                throw errorModel
            }
            return model
        }
        return try configurations.decoder.decode(Model.self, from: data)
    }

}
