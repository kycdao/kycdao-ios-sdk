//
//  Errors.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

public enum KycDaoError: Error {
    case keyGeneration
    case persona(Error)
    case urlRequestError(response: HTTPURLResponse, data: URLRequestErrorData)
    case userAlreadyLoggedIn
    case userNotLoggedIn
    case disclaimerNotAccepted
    case requiredInformationNotProvided
    case identityNotVerified
    case `internal`(KycDaoErrorInternal)
    case missingNetworkConfiguration
    case unsupportedNetwork
    case unauthorizedMinting
}

public enum WalletConnectError: Error {
    case notListening
    case failedToConnect(wallet: Wallet?)
    case sessionFailed
    case sessionNotFoundForWallet
    case failedToSign(String)
    case failedToSendTransaction(String)
    case failedToFetchWalletList
}

public enum URLRequestErrorData {
    case raw(Data)
    case backendError(BackendErrorResponse)
}

public enum KycDaoErrorInternal: Error {
    case missingContractAddress
    case missingBlockchainAccount
    case unknown
}

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
}

enum BackendErrorCode: String, Decodable {
    case disclaimerAlreadyAccepted = "DisclaimerAlreadyAccepted"
    case userAlreadyLoggedIn = "SessionUserAlreadyExists"
}
