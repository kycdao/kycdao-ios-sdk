//
//  KYCDaoContract.swift
//  
//
//  Created by Vekety Robin on 2023. 01. 13..
//

import Foundation
import web3
import BigInt

class KYCDaoContract {
    
    private var contractAddress: EthereumAddress
    private var client: EthereumHttpClient
    
    var subscriptionCostDecimals: Int {
        get async throws {
            let getSubscriptionCostDecimals = GetSubscriptionCostDecimals(contract: contractAddress)
            let response = try await getSubscriptionCostDecimals.call(withClient: client,
                                                             responseType: GetSubscriptionCostDecimalsResponse.self)
            return response.value
        }
    }
    
    init(contractAddress: EthereumAddress, rpcURL: URL) {
        self.contractAddress = contractAddress
        self.client = EthereumHttpClient(url: rpcURL)
    }
    
    init(contractAddress: EthereumAddress, client: EthereumHttpClient) {
        self.contractAddress = contractAddress
        self.client = client
    }
    
    func getRequiredMintCostForCode(authorizationCode: UInt32, destination: EthereumAddress) async throws -> BigUInt {
        
        let getRequiredMintingCostFunction = GetRequiredMintCostForCodeFunction(contract: contractAddress,
                                                                                    authCode: authorizationCode,
                                                                                    destination: destination)
        
        let result = try await getRequiredMintingCostFunction.call(withClient: client,
                                                                   responseType: GetRequiredMintCostForCodeResponse.self)
        
        return result.value
        
    }
    
    func getRequiredMintCostForSeconds(seconds: UInt32) async throws -> BigUInt {
        
        let getRequiredMintingCostFunction = GetRequiredMintCostForSecondsFunction(contract: contractAddress,
                                                                                   seconds: seconds)
        
        let result = try await getRequiredMintingCostFunction.call(withClient: client,
                                                                   responseType: GetRequiredMintCostForSecondsResponse.self)
        
        return result.value
        
    }
    
    func getSubscriptionCostPerYearUSD() async throws -> BigUInt {
        let getSubscriptionCostFunction = GetSubscriptionCostPerYearUSDFunction(contract: contractAddress)
        let result = try await getSubscriptionCostFunction.call(withClient: client,
                                                                                responseType: GetSubscriptionCostPerYearUSDResponse.self)
        
        return result.value
    }
    
    func hasValidToken(walletAddress: EthereumAddress) async throws -> Bool {
        
        let mintingFunction = HasValidTokenFunction(contract: contractAddress, address: walletAddress)
        let result = try await mintingFunction.call(withClient: client, responseType: HasValidTokenResponse.self)
        
        return result.value
        
    }
    
    func mintWithCode(
        authorizationCode: UInt32,
        walletAddress: EthereumAddress,
        cost: BigUInt
    ) throws -> EthereumTransaction {
        let mintingFunction = MintWithCodeFunction(contract: contractAddress,
                                                   authCode: authorizationCode,
                                                   from: walletAddress,
                                                   gasPrice: nil,
                                                   gasLimit: nil)
        let mintingTransaction = try mintingFunction.transaction(value: cost)
        return mintingTransaction
    }
    
}

extension KYCDaoContract {
    
    struct GetSubscriptionCostDecimals: ABIFunction {
        
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

    struct GetSubscriptionCostDecimalsResponse: ABIResponse, MulticallDecodableResponse {
        public static var types: [ABIType.Type] = [ BigUInt.self ]
        public let value: Int
        
        public init?(values: [ABIDecoder.DecodedValue]) throws {
            let bigValue: BigUInt = try values[0].decoded()
            //The number of decimals received should not be greater than 256, it should be safely casted to Int
            guard bigValue < 256 else { throw KycDaoError.internal(.unknown) }
            self.value = Int(bigValue)
        }
    }
    
    struct GetRequiredMintCostForCodeFunction: ABIFunction {
        
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

    struct GetRequiredMintCostForCodeResponse: ABIResponse, MulticallDecodableResponse {
        internal static var types: [ABIType.Type] = [ BigUInt.self ]
        internal let value: BigUInt

        internal init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }
    
    struct GetRequiredMintCostForSecondsFunction: ABIFunction {
        
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

    struct GetRequiredMintCostForSecondsResponse: ABIResponse, MulticallDecodableResponse {
        internal static var types: [ABIType.Type] = [ BigUInt.self ]
        internal let value: BigUInt

        internal init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }
    
    struct GetSubscriptionCostPerYearUSDFunction: ABIFunction {
        
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

    struct GetSubscriptionCostPerYearUSDResponse: ABIResponse, MulticallDecodableResponse {
        internal static var types: [ABIType.Type] = [ BigUInt.self ]
        internal let value: BigUInt

        internal init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }
    
    struct HasValidTokenFunction: ABIFunction {
        
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

    struct HasValidTokenResponse: ABIResponse, MulticallDecodableResponse {
        internal static var types: [ABIType.Type] = [ Bool.self ]
        internal let value: Bool

        internal init?(values: [ABIDecoder.DecodedValue]) throws {
            self.value = try values[0].decoded()
        }
    }
    
    struct MintWithCodeFunction: ABIFunction {
        
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
    
}
