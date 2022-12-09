//
//  Errors.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

public enum KycDaoError: Error {
    case walletConnect(WalletConnectError)
    case keyGeneration
    case persona(Error)
    case httpStatusCode(response: HTTPURLResponse, data: Data)
    case unsupportedNetwork
    case genericError
    case unauthorizedMinting
}

public enum WalletConnectError: Error {
    case failedToConnect(wallet: Wallet?)
    case sessionFailed
    case signingError(String)
}

struct BackendErrorResponse: Decodable {
    let reference_id: String?
    let status_code: Int?
    let `internal`: Bool?
    let error_code: BackendErrorCode?
}

enum BackendErrorCode: String, Decodable {
    case disclaimerAlreadyAccepted = "DisclaimerAlreadyAccepted"
}
