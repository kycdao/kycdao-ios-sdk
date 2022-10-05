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
