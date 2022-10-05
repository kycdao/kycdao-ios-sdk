//
//  WalletSession.swift
//  
//
//  Created by Vekety Robin on 2022. 07. 04..
//

import Foundation
import WalletConnectSwift

public protocol WalletSessionProtocol {
    
    var id: String { get }
    
    //Chain IDs must be specified in CAIP-2 format https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md
    var chainId: String { get }
    
    func personalSign(walletAddress: String, message: String) async throws -> String
    func sendMintingTransaction(walletAddress: String, mintingProperties: MintingProperties) async throws -> String
    
}

public struct WalletSession: Codable, Identifiable, WalletSessionProtocol {
    
    public var id: String {
        url.absoluteString
    }
    
    internal let wcSession: WalletConnectSwift.Session
    private let walletInfo: WalletConnectSwift.Session.WalletInfo
    
    let wallet: Wallet?
    
    public var walletId: String? {
        wallet?.id
    }
    
    public var accounts: [String] {
        walletInfo.accounts
    }
    
    public var icon: URL? {
        wallet?.imageURL ?? walletInfo.peerMeta.icons.first
    }
    
    public var name: String {
        wallet?.name ?? walletInfo.peerMeta.name
    }
    
    public var url: WCURL {
        wcSession.url
    }
    
    public let chainId: String
    
    var status: SessionStatus
    var state: ConnectionState
    
    init(session: WalletConnectSwift.Session, wallet: Wallet?, status: SessionStatus, state: ConnectionState) throws {
        
        guard let walletInfo = session.walletInfo else { throw KYCError.walletConnect(.sessionFailed) }
        
        let caip2Id = "eip155:\(walletInfo.chainId)"
        
        self.wcSession = session
        self.walletInfo = walletInfo
        self.wallet = wallet
        self.status = status
        self.state = state
        self.chainId = caip2Id
    }
    
    public func personalSign(walletAddress: String, message: String) async throws -> String {
        if let wallet = self.wallet {
            return try await WalletConnectManager.shared.sign(account: walletAddress, message: message, wallet: wallet)
        }
        
        return try await WalletConnectManager.shared.sign(account: walletAddress, message: message, url: wcSession.url)
    }
    
    public func sendMintingTransaction(walletAddress: String, mintingProperties: MintingProperties) async throws -> String {
        
        let transaction =  WalletConnectSwift.Client.Transaction(from: walletAddress,
                                                                 to: mintingProperties.contractAddress,
                                                                 data: mintingProperties.contractABI,
                                                                 gas: mintingProperties.gasAmount,
                                                                 gasPrice: mintingProperties.gasPrice,
                                                                 value: nil,
                                                                 nonce: nil,
                                                                 type: nil,
                                                                 accessList: nil,
                                                                 chainId: nil,
                                                                 maxPriorityFeePerGas: nil,
                                                                 maxFeePerGas: nil)
        
        if let wallet = self.wallet {
            return try await WalletConnectManager.shared.sendTransaction(transaction: transaction, wallet: wallet)
        }
        
        return try await WalletConnectManager.shared.sendTransaction(transaction: transaction, url: wcSession.url)
        
    }
}

extension WalletSession: Equatable {
    
    public static func == (lhs: WalletSession, rhs: WalletSession) -> Bool {
        return lhs.id == rhs.id
    }
    
}
