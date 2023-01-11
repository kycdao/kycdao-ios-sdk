//
//  File.swift
//  
//
//  Created by Vekety Robin on 2023. 01. 11..
//

import Foundation

/// The protocol describes a communication session with a wallet that can be used during the verification process.
///
/// #### Wallets
/// Use this protocol, when you want to integrate the kycDAO SDK to your wallet. Provide a concrete implementation of the protocol in a class. Learn more at <doc:WalletIntegration> about integrating the SDK to a wallet.
///
/// #### DApps
/// For DApps integrating the kycDAO SDK, you will likely won't have to use this protocol. WalletConnect should be used to connect your DApp to a supported Wallet. Learn more at <doc:DAppIntegration> about integrating the SDK to a DApp.
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
    func sendMintingTransaction(walletAddress: String, mintingProperties: MintingProperties) async throws -> MintingTransactionResult
    
}
