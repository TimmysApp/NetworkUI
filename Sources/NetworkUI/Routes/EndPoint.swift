//
//  File.swift
//  
//
//  Created by Joe Maghzal on 9/27/22.
//

import Foundation

public protocol EndPoint {
    var baseURL: URL? {get}
    var route: URLRoute {get}
    var method: RequestMethod {get}
    var body: JSON? {get}
    var headers: [Header] {get}
    var retryCount: Int? {get}
    var id: CustomStringConvertible {get}
    func reprocess(url: URL?) -> URL?
}

public extension EndPoint {
    var baseURL: URL? {
        return nil
    }
    var headers: [Header] {
        return []
    }
    var retryCount: Int? {
        return nil
    }
    var id: CustomStringConvertible {
        return (baseURL?.absoluteString ?? "") + method.rawValue + route.components.description
    }
    var body: JSON? {
        return nil
    }
    func reprocess(url: URL?) -> URL? {
        return url
    }
}
