//
//  File.swift
//  
//
//  Created by Joe Maghzal on 9/27/22.
//

import SwiftUI

public protocol ErrorConfigurations {
    associatedtype Body: View
    func shouldDisplay(_ error: NetworkError) -> Bool
    func shouldRetry(_ error: NetworkError) -> Int?
    func handle(_ error: NetworkError)
    func error(_ data: NetworkData) -> Body
}

public extension ErrorConfigurations {
    func shouldDisplay(_ error: NetworkError) -> Bool {
        return true
    }
    func shouldRetry(_ error: NetworkError) -> Int? {
        return nil
    }
    func handle(_ error: NetworkError) {
    }
}

public struct NetworkError: Error {
    var title: String?
    var body: String?
}
