import Foundation
import Combine

///NetworkUI: The Network actor that handles requests
public actor Network: NetworkRequestable {
//MARK: - Properties
    public var configurations: NetworkConfigurations
    public var session: URLSession
//MARK: - Initializer
///NetworkUI: Initializer a `Network` instance using `NetworkConfigurations`
    public init(configurations: NetworkConfigurations = DefaultConfigurations(), session: URLSession = .shared) {
        self.configurations = configurations
        self.session = session
    }
//MARK: - Request Builder
    internal func requestBuilder(route: Route) throws -> URLRequest {
        var requestURL: URL?
        if let baseURL = route.baseURL {
            let reproccessed = route.route.reproccessed(with: route.reprocess(url: route.route.applied(to: baseURL)))
            requestURL = reproccessed
        }else if let baseURL = configurations.baseURL {
            let reproccessed = route.route.reproccessed(with: configurations.reprocess(url: route.route.applied(to: baseURL)))
            requestURL = reproccessed
        }else {
            throw NetworkError(title: "Error", body: "No Base URL found!")
        }
        guard let requestURL else {
            throw NetworkError(title: "Error", body: "The constructed URL is invalid!")
        }
        var request = URLRequest(url: requestURL, timeoutInterval:  configurations.timeoutInterval)
        request.httpMethod = route.method.rawValue
        request.cachePolicy = configurations.cachePolicy
        var headers = route.headers
        if let data = route.body?.data {
            request.httpBody = data
            headers.append(.content(type: .applicationJson))
        }else if !route.formData.isEmpty {
            let boundary = "Boundary-\(UUID().uuidString)"
            var body = Data()
            route.formData.forEach { parameter in
                body.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
                body.append("Content-Disposition:form-data; name=\"\(parameter.key)\"".data(using: .utf8) ?? Data())
                if let stringValue = parameter.stringValue {
                    body.append("\r\n\r\n\(stringValue)\r\n".data(using: .utf8) ?? Data())
                }else if let dataValue = parameter.dataValue {
                    body.append("; filename=\"\(parameter.fileName ?? UUID().uuidString)\"\r\nContent-Type: \"content-type header\"\r\n\r\n".data(using: .utf8) ?? Data())
                    body.append(dataValue)
                }
            }
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8) ?? Data())
            request.httpBody = body
            var header = Header.content(type: .multipartFormData)
            header.value += boundary
            headers.append(header)
        }
        request.configure(headers: headers)
        return request
    }
//MARK: - Result Builder
    internal func resultBuilder<Model: Decodable, ErrorModel: Error & Decodable>(call: NetworkCall<Model, ErrorModel>, request: URLRequest, data: (Data, URLResponse)) async throws -> Model {
        let status = ResponseStatus(statusCode: (data.1 as? HTTPURLResponse)?.statusCode ?? 0)
        RequestLogger.end(request: request, with: (data.0, status))
        if let map = call.map {
            await configurations.interceptor.callDidEnd(call)
            return try map(status)
        }
        let decoder = call.decoder ?? configurations.decoder
        do {
            let model = try decoder.decode(Model.self, from: data.0)
            if model is EmptyData && call.errorModel != nil, let errorModel = try? decoder.decode(ErrorModel.self, from: data.0) {
                throw errorModel
            }
            if let validity = call.validCode, !(try validity(status)) {
                throw NetworkError.unnaceptable(status: status)
            }
            await configurations.interceptor.callDidEnd(call)
            return model
        }catch let modelError {
            if call.errorModel != nil {
                do {
                    let errorModel = try decoder.decode(ErrorModel.self, from: data.0)
                    throw errorModel
                }catch let errorModelError {
                    throw errorModelError
                }
            }
            throw modelError
        }
    }
}