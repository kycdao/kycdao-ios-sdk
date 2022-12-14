//
//  MintingTransactionResult.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 14..
//

import Foundation

public struct MintingTransactionResult: Codable {
    public let txHash: String
    
    public init(txHash: String) {
        self.txHash = txHash
    }
}
