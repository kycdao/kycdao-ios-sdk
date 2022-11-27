//
//  WalletSession.swift
//  
//
//  Created by Vekety Robin on 2022. 07. 04..
//

import Foundation
import WalletConnectSwift

/// The protocol describes a communication session with a wallet that can be used during the verification process.
///
/// #### Wallets
/// Use this protocol, when you want to integrate the kycDAO SDK to you wallet. Provide a concrete implementation of the protocol in a class. Learn more at <doc:WalletIntegration> about integrating the SDK to a wallet.
///
/// #### DApps
/// For DApps integrating the kycDAO SDK, you will likely won't have to use this protocol. WalletConnect should be used to connect your DApp to a supported Wallet.
public protocol WalletSessionProtocol {
    
    /// A unique identifier of the session
    var id: String { get }
    
    /// The ID of the chain used specified in [CAIP-2 format](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md)
    var chainId: String { get }
    
    /// A function used for signing a message with the wallet app
    /// - Parameters:
    ///   - walletAddress: The public address of the wallet we want to sign our data with
    ///   - message: The message we want the wallet app to sign
    /// - Returns: The signed message returned by the wallet app
    func personalSign(walletAddress: String, message: String) async throws -> String
    
    /// A function used for sending a minting transaction with the wallet app
    /// - Parameters:
    ///   - walletAddress: The public address of the wallet we want to send the minting transaction with
    ///   - mintingProperties: Data that describes a transaction used for minting
    /// - Returns: The transaction hash
    func sendMintingTransaction(walletAddress: String, mintingProperties: MintingProperties) async throws -> String
    
}

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
        
        guard let walletInfo = session.walletInfo else { throw KycDaoError.walletConnect(.sessionFailed) }
        
        let caip2Id = "eip155:\(walletInfo.chainId)"
        
        self.wcSession = session
        self.walletInfo = walletInfo
        self.wallet = wallet
        self.chainId = caip2Id
    }
    
    internal func updateSession(_ session: WCSession) throws {
        
        guard let walletInfo = session.walletInfo else { throw KycDaoError.walletConnect(.sessionFailed) }
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

extension WalletConnectSession: Equatable {
    
    public static func == (lhs: WalletConnectSession, rhs: WalletConnectSession) -> Bool {
        return lhs.id == rhs.id
    }
    
}
