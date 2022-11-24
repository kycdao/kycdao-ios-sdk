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
    
    internal var networks: [NetworkMetadata] {
        get async throws {
            let result = try await ApiConnection.call(endPoint: .networks,
                                                      method: .GET,
                                                      output: [NetworkMetadata].self)
            return result.data
        }
    }
    
    private init() { }
    
    /// Creates a ``KycDao/VerificationSession`` which is used for implementing the verification flow
    /// - Parameters:
    ///   - walletAddress: The address of the wallet we are creating the session for
    ///   - walletSession: The ``KycDao/WalletSessionProtocol`` that will be used for signing messages and minting
    /// - Returns: The ``KycDao/VerificationSession`` object
    public func createSession(walletAddress: String, walletSession: WalletSessionProtocol) async throws -> VerificationSession {
        
        let networks = try await self.networks
        guard let selectedNetworkMetadata = networks.first(where: { $0.caip2id == walletSession.chainId })
        else {
            throw KycDaoError.unsupportedNetwork
        }
        
        let apiStatus = try await apiStatus()
        
        guard apiStatus.smartContractsInfo.contains(where: { $0.network == selectedNetworkMetadata.id })
        else {
            throw KycDaoError.unsupportedNetwork
        }
        
        let kycContractConfig = apiStatus.smartContractsInfo.first { $0.network == selectedNetworkMetadata.id && $0.verificationType == .kyc }
        let accreditedInvestorContractConfig = apiStatus.smartContractsInfo.first { $0.network == selectedNetworkMetadata.id && $0.verificationType == .accreditedInvestor }
        
        let chainAndAddress = ChainAndAddressDTO(blockchain: selectedNetworkMetadata.blockchain,
                                                 address: walletAddress)

        let result = try await ApiConnection.call(endPoint: .session,
                                                  method: .POST,
                                                  input: chainAndAddress,
                                                  output: BackendSessionDataDTO.self)
        
        let sessionData = BackendSessionData(dto: result.data)
        
        return VerificationSession(walletAddress: walletAddress,
                          walletSession: walletSession,
                          kycConfig: kycContractConfig,
                          accreditedConfig: accreditedInvestorContractConfig,
                          data: sessionData,
                          networkMetadata: selectedNetworkMetadata)
        
    }
    
    func apiStatus() async throws -> ApiStatus {
        
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
        
        let clientURL = networkOptions.rpcURL ?? URL(string: "https://polygon-mumbai.infura.io/v3/8edae24121f74398b57da7ff5a3729a4")!
        let client = EthereumClient(url: clientURL)
        let contractAddress = EthereumAddress(contractConfig.address)
        let ethWalletAddress = EthereumAddress(walletAddress)
        let mintingFunction = KYCHasValidTokenFunction(contract: contractAddress, address: ethWalletAddress)
        let result = try await mintingFunction.call(withClient: client, responseType: KYCHasValidTokenResponse.self)
        
        return result.value
        
    }
    
}
