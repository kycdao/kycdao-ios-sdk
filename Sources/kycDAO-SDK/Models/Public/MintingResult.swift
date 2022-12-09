//
//  MintingResult.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

/// Describes the results of a successful mint
public struct MintingResult: Encodable {
    
    /// The transaction can be viewed in an explorer by opening the explorer URL
    public let explorerURL: URL?
    
    /// Id of the transaction
    public let transactionId: String
    
    /// Id of the minted token
    public let tokenId: String
    
    /// URL pointing to the minted image
    public let imageURL: URL?
}
