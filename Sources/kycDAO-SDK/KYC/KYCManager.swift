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

public class KYCManager {
    
    public static let shared = KYCManager()
    
    var networks: [NetworkMetadata] {
        get async throws {
            let result = try await KYCConnection.call(endPoint: .networks,
                                                      method: .GET,
                                                      output: [NetworkMetadata].self)
            return result.data
        }
    }
    
    private init() { }
    
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
    
}
