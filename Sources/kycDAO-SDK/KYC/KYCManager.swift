//
//  KYCManager.swift
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

/// A class used for creating KYC sessions and querying KYC status for different wallets
public class KYCManager {
    
    /// KYCManager singleton instance
    public static let shared = KYCManager()
    
    internal var networks: [NetworkMetadata] {
        get async throws {
            let result = try await KYCConnection.call(endPoint: .networks,
                                                      method: .GET,
                                                      output: [NetworkMetadata].self)
            return result.data
        }
    }
    
    private init() { }
    
    /// Creates a ``KycDao/KYCSession`` which is used for implementing the KYC flow
    /// - Parameters:
    ///   - walletAddress: The address of the wallet we are creating the session for
    ///   - walletSession: The ``KycDao/WalletSession`` that will be used for signing messages and minting
    /// - Returns: The ``KycDao/KYCSession`` object
    public func createSession(walletAddress: String, walletSession: WalletSessionProtocol) async throws -> KYCSession {
        
        let networks = try await self.networks
        guard let selectedNetworkMetadata = networks.first(where: { $0.caip2id == walletSession.chainId })
        else {
            throw KYCError.unsupportedNetwork
        }
        
        let apiStatus = try await apiStatus()
        
        guard apiStatus.smartContractsInfo.contains(where: { $0.network == selectedNetworkMetadata.id })
        else {
            throw KYCError.unsupportedNetwork
        }
        
        let kycContractConfig = apiStatus.smartContractsInfo.first { $0.network == selectedNetworkMetadata.id && $0.verificationType == .kyc }
        let accreditedInvestorContractConfig = apiStatus.smartContractsInfo.first { $0.network == selectedNetworkMetadata.id && $0.verificationType == .accreditedInvestor }
        
        let chainAndAddress = ChainAndAddressDTO(blockchain: selectedNetworkMetadata.blockchain,
                                                 address: walletAddress)

        let result = try await KYCConnection.call(endPoint: .session,
                                                  method: .POST,
                                                  input: chainAndAddress,
                                                  output: KYCSessionDataDTO.self)
        
        let sessionData = KYCSessionData(dto: result.data)
        
        return KYCSession(walletAddress: walletAddress,
                          walletSession: walletSession,
                          kycConfig: kycContractConfig,
                          accreditedConfig: accreditedInvestorContractConfig,
                          data: sessionData,
                          networkMetadata: selectedNetworkMetadata)
        
    }
    
    func apiStatus() async throws -> ApiStatus {
        
        let result = try await KYCConnection.call(endPoint: .status, method: .GET, output: ApiStatus.self)
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
                                networkOptions: NetworkOptions(chainId: walletSession.chainId,
                                                               rpcURL: walletSession.rpcURL))
    }
    
    /// Checks on-chain whether the wallet has a valid token for the verification type
    /// - Parameters:
    ///   - verificationType: The type of verification we want to find a valid token for
    ///   - walletAddress: The address of the wallet the token belongs to
    ///   - networkOptions: Network options for setting up the connection
    /// - Returns: True, when the wallet has a valid token for the selected verification type on the given network
    public func hasValidToken(
        verificationType: VerificationType,
        walletAddress: String,
        networkOptions: NetworkOptions
    ) async throws -> Bool {
        
        let networks = try await self.networks
        guard let selectedNetworkMetadata = networks.first(where: { $0.caip2id == networkOptions.chainId })
        else {
            throw KYCError.unsupportedNetwork
        }
        
        let apiStatus = try await apiStatus()
        
        guard apiStatus.smartContractsInfo.contains(where: { $0.network == selectedNetworkMetadata.id })
        else {
            throw KYCError.unsupportedNetwork
        }
        
        let contractConfig = apiStatus.smartContractsInfo.first {
            $0.network == selectedNetworkMetadata.id
            && $0.verificationType == verificationType
        }
        
        guard let contractConfig = contractConfig
        else {
            throw KYCError.unsupportedNetwork
        }
        
        let clientURL = networkOptions.rpcURL ?? URL(string: "https://polygon-mumbai.infura.io/v3/8edae24121f74398b57da7ff5a3729a4")!
        let client = EthereumClient(url: clientURL)
        let contractAddress = EthereumAddress(contractConfig.address)
        let ethWalletAddress = EthereumAddress(walletAddress)
        let mintingFunction = KYCHasValidTokenFunction(contract: contractAddress, address: ethWalletAddress)
        let result = try await mintingFunction.call(withClient: client, responseType: KYCHasValidTokenResponse.self)
        
        return result.value
        
    }
    
}
