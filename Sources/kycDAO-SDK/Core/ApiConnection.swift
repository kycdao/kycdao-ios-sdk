//
//  KYCConnection.swift
//  
//
//  Created by Vekety Robin on 2022. 08. 11..
//

import Foundation

enum EndPoint: String {
    case session = "session"
    case disclaimer = "disclaimer"
    case user = "user"
    case emailConfirmation = "user/email_confirmation"
    case status = "status"
    case authorizeMinting = "authorize_minting"
    case identicon = "token/identicon"
    case token = "token"
    case networks = "networks"
}

enum HTTPMethod: String {
    case GET = "GET"
    case PUT = "PUT"
    case POST = "POST"
    case UPDATE = "UPDATE"
    case DELETE = "DELETE"
}

class ApiConnection {
    
    static var baseURL: String {
        VerificationManager.environment
            .serverURL
            .absoluteString
        + "/api/public/"
    }
    
    static func call<I: Encodable, O: Decodable>(
        endPoint: EndPoint,
        method: HTTPMethod,
        input: I,
        output: O.Type
    ) async throws -> (response: HTTPURLResponse, data: O) {
        
        var request = URLRequest(url: URL(string: baseURL + endPoint.rawValue)!)
        request.httpMethod = method.rawValue
        
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json"
        ]
        
        request.httpBody = try JSONEncoder().encode(input)
        
        print(request.cURL())
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print(response)
        let responseString = String(data: data, encoding: .utf8)
        print("KYC \(endPoint.rawValue) \(method.rawValue) result: \(responseString ?? "")")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KycDaoError.internal(.unknown)
        }
        
        guard 200 ... 299 ~= httpResponse.statusCode else {
            let backendError = try? JSONDecoder().decode(BackendErrorResponse.self, from: data)
            
            if let backendError {
                throw KycDaoError.urlRequestError(response: httpResponse, data: .backendError(backendError))
            } else {
                throw KycDaoError.urlRequestError(response: httpResponse, data: .raw(data))
            }
        }
        
        return (httpResponse, try JSONDecoder().decode(O.self, from: data))
        
    }
    
    @discardableResult
    static func call<I: Encodable>(
        endPoint: EndPoint,
        method: HTTPMethod,
        input: I
    ) async throws -> (response: HTTPURLResponse, data: Data) {
        
        var request = URLRequest(url: URL(string: baseURL + endPoint.rawValue)!)
        request.httpMethod = method.rawValue
        
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json"
        ]
        
        request.httpBody = try JSONEncoder().encode(input)
        
        print(request.cURL())
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print(response)
        let responseString = String(data: data, encoding: .utf8)
        print("KYC \(endPoint.rawValue) \(method.rawValue) result: \(responseString ?? "")")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KycDaoError.internal(.unknown)
        }
        
        guard 200 ... 299 ~= httpResponse.statusCode else {
            let backendError = try? JSONDecoder().decode(BackendErrorResponse.self, from: data)
            
            if let backendError {
                throw KycDaoError.urlRequestError(response: httpResponse, data: .backendError(backendError))
            } else {
                throw KycDaoError.urlRequestError(response: httpResponse, data: .raw(data))
            }
        }
        
        return (httpResponse, data)
        
    }
    
    static func call<O: Decodable>(
        endPoint: EndPoint,
        method: HTTPMethod,
        output: O.Type
    ) async throws -> (response: HTTPURLResponse, data: O) {
        
        var request = URLRequest(url: URL(string: baseURL + endPoint.rawValue)!)
        request.httpMethod = method.rawValue
        
        print(request.cURL())
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print(response)
        let responseString = String(data: data, encoding: .utf8)
        print("KYC \(endPoint.rawValue) \(method.rawValue) result: \(responseString ?? "")")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KycDaoError.internal(.unknown)
        }
        
        guard 200 ... 299 ~= httpResponse.statusCode else {
            let backendError = try? JSONDecoder().decode(BackendErrorResponse.self, from: data)
            
            if let backendError {
                throw KycDaoError.urlRequestError(response: httpResponse, data: .backendError(backendError))
            } else {
                throw KycDaoError.urlRequestError(response: httpResponse, data: .raw(data))
            }
        }
        
        return (httpResponse, try JSONDecoder().decode(O.self, from: data))
        
    }
    
    @discardableResult
    static func call(
        endPoint: EndPoint,
        method: HTTPMethod
    ) async throws -> (response: HTTPURLResponse, data: Data) {
        
        var request = URLRequest(url: URL(string: baseURL + endPoint.rawValue)!)
        request.httpMethod = method.rawValue
        
        print(request.cURL())
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print(response)
        let responseString = String(data: data, encoding: .utf8)
        print("KYC \(endPoint.rawValue) \(method.rawValue) result: \(responseString ?? "")")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KycDaoError.internal(.unknown)
        }
        
        guard 200 ... 299 ~= httpResponse.statusCode else {
            let backendError = try? JSONDecoder().decode(BackendErrorResponse.self, from: data)
            
            if let backendError {
                throw KycDaoError.urlRequestError(response: httpResponse, data: .backendError(backendError))
            } else {
                throw KycDaoError.urlRequestError(response: httpResponse, data: .raw(data))
            }
        }
        
        return (httpResponse, data)
        
    }
    
}
