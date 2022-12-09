//
//  MintingProperties.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

/// Data that describes a transaction used for minting
///
/// All values are in hex
public struct MintingProperties: Codable {
    
    /// The address of the smart contract we want to call
    public let contractAddress: String
    /// The ABI data of the smart contract
    public let contractABI: String
    /// Amount of gas required for minting
    public let gasAmount: String
    /// Price of a gas unit
    public let gasPrice: String
    
    /// The payment amount required to mint
    ///
    /// For EVM chains, this is the `value` field of a transaction object
    public let paymentAmount: String?
    
}
