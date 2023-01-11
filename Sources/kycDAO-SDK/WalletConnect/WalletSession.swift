//
//  WalletSession.swift
//  
//
//  Created by Vekety Robin on 2022. 07. 04..
//

import Foundation
import WalletConnectSwift

/// A class representing a session with a WalletConnect wallet
public class WalletConnectSession: Codable, Identifiable, WalletSessionProtocol {
    
    /// A unique identifier of the session
    public var id: String {
        url.absoluteString
    }
    
    internal var wcSession: WalletConnectSwift.Session
    private var walletInfo: WalletConnectSwift.Session.WalletInfo
    
    internal let wallet: Wallet?
    
    /// ID of a ``KycDao/Wallet`` object belonging to the ``KycDao/WalletSessionProtocol``
    /// - Note: If the session was established as a result of ``KycDao/WalletConnectManager/connect(withWallet:)``, it will contain the id, otherwise `nil`
    public var walletId: String? {
        wallet?.id
    }
    
    /// List of blockchain accounts/wallet addresses accessible through the session
    public var accounts: [String] {
        walletInfo.accounts
    }
    
    /// `URL` for an icon of the wallet app the session belongs to
    public var icon: URL? {
        wallet?.imageURL ?? walletInfo.peerMeta.icons.first
    }
    
    /// Name of the wallet app the session belongs to
    public var name: String {
        wallet?.name ?? walletInfo.peerMeta.name
    }
    
    /// The wallet connect URL as provided by [WalletConnectSwift](https://github.com/WalletConnect/WalletConnectSwift/blob/master/Sources/PublicInterface/WCURL.swift)
    public var url: WCURL {
        wcSession.url
    }
    
    public private(set) var chainId: String
    
    internal init(session: WalletConnectSwift.Session, wallet: Wallet?) throws {
        
        guard let walletInfo = session.walletInfo else { throw WalletConnectError.sessionFailed }
        
        let caip2Id = "eip155:\(walletInfo.chainId)"
        
        self.wcSession = session
        self.walletInfo = walletInfo
        self.wallet = wallet
        self.chainId = caip2Id
    }
    
    internal func updateSession(_ session: WCSession) throws {
        
        guard let walletInfo = session.walletInfo else { throw WalletConnectError.sessionFailed }
        let caip2Id = "eip155:\(walletInfo.chainId)"
        
        self.wcSession = session
        self.walletInfo = walletInfo
        self.chainId = caip2Id
        
    }
    
    public func personalSign(walletAddress: String, message: String) async throws -> String {
        if let wallet = self.wallet {
            return try await WalletConnectManager.shared.sign(account: walletAddress, message: message, wallet: wallet)
        }
        
        return try await WalletConnectManager.shared.sign(account: walletAddress, message: message, url: wcSession.url)
    }
    
    public func sendMintingTransaction(walletAddress: String, mintingProperties: MintingProperties) async throws -> MintingTransactionResult {
        
        let transaction =  WalletConnectSwift.Client.Transaction(from: walletAddress,
                                                                 to: mintingProperties.contractAddress,
                                                                 data: mintingProperties.contractABI,
                                                                 gas: mintingProperties.gasAmount,
                                                                 gasPrice: mintingProperties.gasPrice,
                                                                 value: mintingProperties.paymentAmount,
                                                                 nonce: nil,
                                                                 type: nil,
                                                                 accessList: nil,
                                                                 chainId: nil,
                                                                 maxPriorityFeePerGas: nil,
                                                                 maxFeePerGas: nil)
        
        if let wallet = self.wallet {
            let txHash =  try await WalletConnectManager.shared.sendTransaction(transaction: transaction, wallet: wallet)
            return MintingTransactionResult(txHash: txHash)
        }
        
        let txHash = try await WalletConnectManager.shared.sendTransaction(transaction: transaction, url: wcSession.url)
        return MintingTransactionResult(txHash: txHash)
    }
}

extension WalletConnectSession: Equatable {
    
    public static func == (lhs: WalletConnectSession, rhs: WalletConnectSession) -> Bool {
        return lhs.id == rhs.id
    }
    
}
