//
//  VerificationManager.swift
//  
//
//  Created by Vekety Robin on 2022. 06. 17..
//

import Foundation
import WalletConnectSwift
import UIKit
import Persona2
import Combine
import web3
import BigInt

/// A class used for verification related tasks, like querying verification status for different wallets or creating verification sessions
public class VerificationManager {
    
    /// VerificationManager singleton instance
    public static let shared = VerificationManager()
    
    private static var _configuration: Configuration?
    
    private static var configuration: Configuration {
        if let _configuration {
            return _configuration
        }
        fatalError(
"""
VerificationManager not configured before being used!
Call VerificationManager.configure(_:) before you start using the SDK to resolve this issue
"""
        )
    }
    
//    internal static var apiKey: String {
//        configuration.apiKey
//    }
    
    internal static var environment: KycDaoEnvironment {
        configuration.environment
    }
    
    internal static var networks: [NetworkMetadata] {
        get async throws {
            let result = try await ApiConnection.call(endPoint: .networks,
                                                      method: .GET,
                                                      output: [NetworkMetadata].self)
            return result.data
        }
    }
    
    internal static var networkConfigs: [AppliedNetworkConfig] {
        var appliedDefault = Set(
            DefaultNetworkConfig.allCases.map {
                AppliedNetworkConfig(chainId: $0.chainId, rpcURL: $0.rpcURL)
            }
        )
        
        let appliedCustom: Set<AppliedNetworkConfig> = Set(
            Self.configuration.networkConfigs.compactMap {
                guard let customRPCURL = $0.rpcURL else { return nil }
                return AppliedNetworkConfig(chainId: $0.chainId, rpcURL: customRPCURL)
            }
        )
        
        let missingDefault = appliedDefault.subtracting(appliedCustom)
        return Array(appliedCustom.union(missingDefault))
    }
    
    //Currently not throwing neither async but once default RPC URLs will be provided from backend, it will require booth
    internal static func networkConfig(forChainId chainId: String) async throws -> AppliedNetworkConfig {
        
        let defaultForCurrent = DefaultNetworkConfig.allCases.first {
            $0.chainId == chainId
        }
        
        let thisConfig = configuration.networkConfigs.first {
            $0.chainId == chainId
        }
        
        var mergedConfig = defaultForCurrent.map { defaultConfig -> AppliedNetworkConfig in
            
            let appliedConfig = thisConfig.map {
                AppliedNetworkConfig(chainId: $0.chainId,
                                     rpcURL: $0.rpcURL ?? defaultConfig.rpcURL)
            }
            
            return appliedConfig ?? defaultConfig.asAppliedNetworkConfig
        }
        
        if mergedConfig == nil, let rpc = thisConfig?.rpcURL {
            mergedConfig = AppliedNetworkConfig(chainId: chainId, rpcURL: rpc)
        }
        
        guard let mergedConfig else {
            // Config error, network does not have default configs in the SDK and no custom configs can be found for it
            throw KycDaoError.missingNetworkConfiguration
        }
        
        return mergedConfig
        
    }
    
    /// Initializes the SDK with a configuration
    /// - Parameter configuration: The configuration options for the SDK
    /// - Important: You have to provide a configuration for the SDK **before** using it. Configuration can only be set **once** per app launch
    public static func configure(_ configuration: Configuration) {
        guard _configuration == nil else {
            // Disallow reconfiguration after initial configuration
            print("Reconfiguration is not allowed!!!")
            return
        }
        
        Self._configuration = configuration
    }
    
    private init() { }
    
    /// Creates a ``KycDao/VerificationSession`` which is used for implementing the verification flow
    /// - Parameters:
    ///   - walletAddress: The address of the wallet we are creating the session for
    ///   - walletSession: The ``KycDao/WalletSessionProtocol`` that will be used for signing messages and minting
    /// - Returns: The ``KycDao/VerificationSession`` object
    public func createSession(walletAddress: String, walletSession: WalletSessionProtocol) async throws -> VerificationSession {
        
        let networks = try await Self.networks
        guard let selectedNetworkMetadata = networks.first(where: { $0.caip2id == walletSession.chainId })
        else {
            throw KycDaoError.unsupportedNetwork
        }
        
        let apiStatus = try await apiStatus()
        
        guard apiStatus.smartContractsInfo.contains(where: { $0.network == selectedNetworkMetadata.id })
        else {
            throw KycDaoError.unsupportedNetwork
        }
        
        let kycContractConfig = apiStatus.smartContractsInfo.first {
            $0.network == selectedNetworkMetadata.id
            && $0.verificationType == .kyc
        }
        
        let accreditedInvestorContractConfig = apiStatus.smartContractsInfo.first {
            $0.network == selectedNetworkMetadata.id
            && $0.verificationType == .accreditedInvestor
        }
        
        let chainAndAddress = ChainAndAddressDTO(blockchain: selectedNetworkMetadata.blockchain,
                                                 address: walletAddress)

        let result = try await ApiConnection.call(endPoint: .session,
                                                  method: .POST,
                                                  input: chainAndAddress,
                                                  output: BackendSessionDataDTO.self)
        
        let sessionData = BackendSessionData(dto: result.data)
        
        let networkConfig = try await Self.networkConfig(forChainId: selectedNetworkMetadata.caip2id)
        
        return VerificationSession(walletAddress: walletAddress,
                                   walletSession: walletSession,
                                   kycConfig: kycContractConfig,
                                   accreditedConfig: accreditedInvestorContractConfig,
                                   data: sessionData,
                                   networkMetadata: selectedNetworkMetadata,
                                   networkConfig: networkConfig)
        
    }
    
    internal func apiStatus() async throws -> ApiStatus {
        
        let result = try await ApiConnection.call(endPoint: .status, method: .GET, output: ApiStatus.self)
        return result.data
        
    }
    
    /// Checks on-chain whether the wallet has a valid token for the verification type
    /// - Parameters:
    ///   - verificationType: The type of verification we want to find a valid token for
    ///   - walletAddress: The address of the wallet the token belongs to
    ///   - walletSession: A WalletSession instance
    /// - Returns: True, when the wallet has a valid token for the selected verification type on the wallet session's network
    public func hasValidToken(
        verificationType: VerificationType,
        walletAddress: String,
        walletSession: WalletSessionProtocol
    ) async throws -> Bool {
        try await hasValidToken(verificationType: verificationType,
                                walletAddress: walletAddress,
                                chainId: walletSession.chainId)
    }
    
    /// Checks on-chain whether the wallet has a valid token for the verification type
    /// - Parameters:
    ///   - verificationType: The type of verification we want to find a valid token for
    ///   - walletAddress: The address of the wallet the token belongs to
    ///   - chainId: [CAIP-2](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md) chain id of the network to use
    /// - Returns: True, when the wallet has a valid token for the selected verification type on the given network
    public func hasValidToken(
        verificationType: VerificationType,
        walletAddress: String,
        chainId: String
    ) async throws -> Bool {
        
        let rpcURL = try await Self.networkConfig(forChainId: chainId).rpcURL

        let networks = try await Self.networks
        guard let selectedNetworkMetadata = networks.first(where: { $0.caip2id == chainId })
        else {
            throw KycDaoError.unsupportedNetwork
        }
        
        let apiStatus = try await apiStatus()
        
        guard apiStatus.smartContractsInfo.contains(where: { $0.network == selectedNetworkMetadata.id })
        else {
            throw KycDaoError.unsupportedNetwork
        }
        
        let contractConfig = apiStatus.smartContractsInfo.first {
            $0.network == selectedNetworkMetadata.id
            && $0.verificationType == verificationType
        }
        
        guard let contractConfig = contractConfig
        else {
            throw KycDaoError.unsupportedNetwork
        }
        
        let client = EthereumHttpClient(url: rpcURL)
        let contractAddress = EthereumAddress(contractConfig.address)
        let ethWalletAddress = EthereumAddress(walletAddress)
        let mintingFunction = KYCHasValidTokenFunction(contract: contractAddress, address: ethWalletAddress)
        let result = try await mintingFunction.call(withClient: client, responseType: KYCHasValidTokenResponse.self)
        
        return result.value
        
    }
    
    /// Checks on-chain whether the wallet has a valid token for the verification type
    /// - Parameters:
    ///   - verificationType: The type of verification we want to find a valid token for
    ///   - walletAddress: The address of the wallet the token belongs to
    ///   - chainId: [CAIP-2](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md) chain id of the network to use
    /// - Returns: True, when the wallet has a valid token for the selected verification type on the given network
    public func checkVerifiedNetworks(
        verificationType: VerificationType,
        walletAddress: String
    ) async throws -> [String: Bool] {
        
        let networkConfigs = Self.networkConfigs
        let networks = try await Self.networks
        let apiStatus = try await apiStatus()
        var verifications: [String: Bool] = [:]
        
        for networkConfig in networkConfigs {
            
            guard let selectedNetworkMetadata = networks.first(where: { $0.caip2id == networkConfig.chainId }),
                  apiStatus.smartContractsInfo.contains(where: { $0.network == selectedNetworkMetadata.id })
            else {
                verifications[networkConfig.chainId] = false
                continue
            }
            
            let contractConfig = apiStatus.smartContractsInfo.first {
                $0.network == selectedNetworkMetadata.id
                && $0.verificationType == verificationType
            }
            
            guard let contractConfig
            else {
                verifications[networkConfig.chainId] = false
                continue
            }
            
            let client = EthereumHttpClient(url: networkConfig.rpcURL)
            let contractAddress = EthereumAddress(contractConfig.address)
            let ethWalletAddress = EthereumAddress(walletAddress)
            let mintingFunction = KYCHasValidTokenFunction(contract: contractAddress, address: ethWalletAddress)
            let result = try await mintingFunction.call(withClient: client, responseType: KYCHasValidTokenResponse.self)
            
            verifications[networkConfig.chainId] = result.value
            
        }
        
        return verifications
        
    }
    
}
