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
    
    public static let name = "mintWithCode"
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

struct KYCGetSubscriptionCostPerYearUSDFunction: ABIFunction {
    
    public static let name = "getSubscriptionCostPerYearUSD"
    public let gasPrice: BigUInt?
    public let gasLimit: BigUInt?
    public var contract: EthereumAddress
    public let from: EthereumAddress?

    public init(contract: EthereumAddress,
                from: EthereumAddress? = nil,
                gasPrice: BigUInt? = nil,
                gasLimit: BigUInt? = nil) {
        self.contract = contract
        self.from = from
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
    }

    public func encode(to encoder: ABIFunctionEncoder) throws {
    }
    
}

internal struct KYCGetSubscriptionCostPerYearUSDResponse: ABIResponse, MulticallDecodableResponse {
    internal static var types: [ABIType.Type] = [ BigUInt.self ]
    internal let value: BigUInt

    internal init?(values: [ABIDecoder.DecodedValue]) throws {
        self.value = try values[0].decoded()
    }
}

struct KYCGetRequiredMintCostForCodeFunction: ABIFunction {
    
    public static let name = "getRequiredMintCostForCode"
    public let gasPrice: BigUInt?
    public let gasLimit: BigUInt?
    public var contract: EthereumAddress
    public let from: EthereumAddress?

    public let authCode: UInt32
    public let destination: EthereumAddress

    public init(contract: EthereumAddress,
                authCode: UInt32,
                destination: EthereumAddress,
                from: EthereumAddress? = nil,
                gasPrice: BigUInt? = nil,
                gasLimit: BigUInt? = nil) {
        self.contract = contract
        self.from = from
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        
        self.authCode = authCode
        self.destination = destination
    }

    public func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(authCode)
        try encoder.encode(destination)
    }
    
}

internal struct KYCGetRequiredMintCostForCodeResponse: ABIResponse, MulticallDecodableResponse {
    internal static var types: [ABIType.Type] = [ BigUInt.self ]
    internal let value: BigUInt

    internal init?(values: [ABIDecoder.DecodedValue]) throws {
        self.value = try values[0].decoded()
    }
}

struct KYCGetRequiredMintCostForSecondsFunction: ABIFunction {
    
    public static let name = "getRequiredMintCostForSeconds"
    public let gasPrice: BigUInt?
    public let gasLimit: BigUInt?
    public var contract: EthereumAddress
    public let from: EthereumAddress?

    public let seconds: UInt32

    public init(contract: EthereumAddress,
                seconds: UInt32,
                from: EthereumAddress? = nil,
                gasPrice: BigUInt? = nil,
                gasLimit: BigUInt? = nil) {
        self.contract = contract
        self.from = from
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        
        self.seconds = seconds
    }

    public func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(seconds)
    }
    
}

internal struct KYCGetRequiredMintCostForSecondsResponse: ABIResponse, MulticallDecodableResponse {
    internal static var types: [ABIType.Type] = [ BigUInt.self ]
    internal let value: BigUInt

    internal init?(values: [ABIDecoder.DecodedValue]) throws {
        self.value = try values[0].decoded()
    }
}

struct KYCGetSubscriptionCostDecimals: ABIFunction {
    
    public static let name = "SUBSCRIPTION_COST_DECIMALS"
    public let gasPrice: BigUInt?
    public let gasLimit: BigUInt?
    public var contract: EthereumAddress
    public let from: EthereumAddress?
    
    public init(contract: EthereumAddress,
                from: EthereumAddress? = nil,
                gasPrice: BigUInt? = nil,
                gasLimit: BigUInt? = nil) {
        self.contract = contract
        self.from = from
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
    }
    
    public func encode(to encoder: ABIFunctionEncoder) throws {
    }
    
}

internal struct KYCGetSubscriptionCostDecimalsResponse: ABIResponse, MulticallDecodableResponse {
    public static var types: [ABIType.Type] = [ BigUInt.self ]
    public let value: Int
    
    public init?(values: [ABIDecoder.DecodedValue]) throws {
        let bigValue: BigUInt = try values[0].decoded()
        //The number of decimals received should not be greater than 256, it should be safely casted to Int
        guard bigValue < 256 else { throw KycDaoError.internal(.unknown) }
        self.value = Int(bigValue)
    }
}
