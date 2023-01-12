//
//  MintingTransactionResult.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 14..
//

import Foundation

/// Result of a minting transaction
public struct MintingTransactionResult: Codable {
    /// Transaction hash
    public let txHash: String
    
    public init(txHash: String) {
        self.txHash = txHash
    }
}
