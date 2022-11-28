//
//  KYCMintingFunction.swift
//  
//
//  Created by Vekety Robin on 2022. 08. 11..
//

import Foundation
import web3
import BigInt

struct KYCMintingFunction: ABIFunction {
    
    public static let name = "mint"
    public let gasPrice: BigUInt?
    public let gasLimit: BigUInt?
    public var contract: EthereumAddress
    public let from: EthereumAddress?

    public let authCode: UInt32

    public init(contract: EthereumAddress,
                authCode: UInt32,
                from: EthereumAddress? = nil,
                gasPrice: BigUInt? = nil,
                gasLimit: BigUInt? = nil) {
        self.contract = contract
        self.from = from
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        
        self.authCode = authCode
    }

    public func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(authCode)
    }
    
}

struct KYCHasValidTokenFunction: ABIFunction {
    
    public static let name = "hasValidToken"
    public let gasPrice: BigUInt?
    public let gasLimit: BigUInt?
    public var contract: EthereumAddress
    public let from: EthereumAddress?

    public let address: EthereumAddress

    public init(contract: EthereumAddress,
                address: EthereumAddress,
                from: EthereumAddress? = nil,
                gasPrice: BigUInt? = nil,
                gasLimit: BigUInt? = nil) {
        self.contract = contract
        self.from = from
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        
        self.address = address
    }

    public func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(address)
    }
    
}

internal struct KYCHasValidTokenResponse: ABIResponse, MulticallDecodableResponse {
    internal static var types: [ABIType.Type] = [ Bool.self ]
    internal let value: Bool

    internal init?(values: [ABIDecoder.DecodedValue]) throws {
        self.value = try values[0].decoded()
    }
}