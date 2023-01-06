//
//  Errors.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

/// KycDao services related errors
public enum KycDaoError: LocalizedError {
    /// Error originating from persona
    case persona(Error)
    /// Error related to an URL request
    case urlRequestError(response: HTTPURLResponse, data: URLRequestErrorData)
    /// The user is already logged in
    case userAlreadyLoggedIn
    /// The user is not logged in
    case userNotLoggedIn
    /// The user does not have an accepted disclaimer
    case disclaimerNotAccepted
    /// One or more required user informations are not set
    case requiredInformationNotProvided
    /// Identity is not verified for the user
    case identityNotVerified
    /// An internal error occurred which likely can't be solved by the SDK's integrator
    case `internal`(KycDaoErrorInternal)
    /// Network configuration not found for the selected chain
    case missingNetworkConfiguration
    /// Network is not supported by KycDao services
    case unsupportedNetwork
    /// Minting authorization is reuired for the operation but wasn't provided
    case unauthorizedMinting
    
    public var errorDescription: String? {
        switch self {
        case .persona(let error):
            return "Persona threw the following error: \(error)"
        case .urlRequestError(response: let response, data: let data):
            var errorString = "An error occurred while accessing \(response.url?.absoluteString ?? "unknown URL") which returned with status code \(response.statusCode)."
            if case let .backendError(backendErrorResponse) = data, let errorCode = backendErrorResponse.errorCode {
                errorString = errorString + " The backend responded with \(errorCode)"
            }
            return errorString
        case .userAlreadyLoggedIn:
            return "The user is already logged in to this session"
        case .userNotLoggedIn:
            return "The operation could not be completed: user is not logged in"
        case .disclaimerNotAccepted:
            return "The opertaion could not be completed: the user did not accept the disclaimer"
        case .requiredInformationNotProvided:
            return "The operation could not be completed: some required user informations were not provided. Email and country of residency are required."
        case .identityNotVerified:
            return "The operation could not be completed: user not verified"
        case .internal(let internalError):
            switch internalError {
            case .missingContractAddress:
                return "An internal error occurred: contract address information missing"
            case .missingBlockchainAccount:
                return "An internal error occurred: blockchain account missing for the user"
            case .unknown:
                return "An unkown, unexpected internal error occurred that should not happen"
            }
        case .missingNetworkConfiguration:
            return "Network does not have default configs in the SDK and no custom configs can be found for it. Try setting a configuration for the network."
        case .unsupportedNetwork:
            return "Network not supported by kycDAO services"
        case .unauthorizedMinting:
            return "The operation could not be completed: minting not authorized"
        }
    }
}

/// WalletConnect related errors
public enum WalletConnectError: LocalizedError {
    /// WalletConnectManager is not listening
    case notListening
    /// Failed to connect to wallet
    case failedToConnect(wallet: Wallet?)
    /// The existing wallet connect session failed
    case sessionFailed
    /// Session not found for the wallet
    case sessionNotFoundForWallet
    /// Failed to sign message. Error details are in the String parameter
    case failedToSign(String)
    /// Failed to send transaction. Error details are in the String parameter
    case failedToSendTransaction(String)
    /// Failed to fetch wallet list provided by WalletConnect registry
    case failedToFetchWalletList
    
    public var errorDescription: String? {
        switch self {
        case .notListening:
            return "Operation could not be completed: WalletConnectManager not listening"
        case .failedToConnect(let wallet):
            return "Failed to connect wallet \(wallet?.name ?? "")"
        case .sessionFailed:
            return "WalletConnect session failed"
        case .sessionNotFoundForWallet:
            return "WalletConnect session not found for wallet"
        case .failedToSign(let errorString):
            return "Failed to sign the message due to an error: \(errorString)"
        case .failedToSendTransaction(let errorString):
            return "Failed to send transaction due to an error: \(errorString)"
        case .failedToFetchWalletList:
            return "Failed to fetch wallet list"
        }
    }
}

/// Data part of an URLRequest related error
public enum URLRequestErrorData {
    case raw(Data)
    case backendError(BackendErrorResponse)
}

/// Errors the SDK's integrator probably can't recover from
public enum KycDaoErrorInternal: Error {
    /// KycDao contract address can not be found for the selected chain
    case missingContractAddress
    /// Blockchain account address can not be found for the user
    case missingBlockchainAccount
    /// An unknown internal error occurred
    case unknown
}

/// Decoded error response data received from the backend service
public struct BackendErrorResponse: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case `internal`
        case statusCode = "status_code"
        case referenceId = "reference_id"
        case errorCode = "error_code"
    }
    
    let referenceId: String?
    let statusCode: Int?
    let `internal`: Bool?
    let errorCode: BackendErrorCode?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.internal = try container.decodeIfPresent(Bool.self, forKey: .internal)
        self.statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
        self.referenceId = try container.decodeIfPresent(String.self, forKey: .referenceId)
        let rawErrorCode = try container.decodeIfPresent(String.self, forKey: .errorCode)
        if let rawErrorCode, let errorCodeDTO = BackendErrorCodeDTO(rawValue: rawErrorCode) {
            self.errorCode = BackendErrorCode(dto: errorCodeDTO)
        } else {
            self.errorCode = .unknown(errorCode: rawErrorCode)
        }
    }
}

enum BackendErrorCodeDTO: String, Decodable {
    case disclaimerAlreadyAccepted = "DisclaimerAlreadyAccepted"
    case userAlreadyLoggedIn = "SessionUserAlreadyExists"
}

/// The decoded error code received from the backend
public enum BackendErrorCode: Equatable {
    case disclaimerAlreadyAccepted
    case userAlreadyLoggedIn
    case unknown(errorCode: String?)
    
    init(dto: BackendErrorCodeDTO) {
        switch dto {
        case .disclaimerAlreadyAccepted:
            self = .disclaimerAlreadyAccepted
        case .userAlreadyLoggedIn:
            self = .userAlreadyLoggedIn
        }
    }
}
