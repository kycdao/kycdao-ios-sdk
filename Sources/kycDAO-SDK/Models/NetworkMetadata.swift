//
//  NetworkMetadata.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

struct NetworkMetadata: Codable {
    
    let id: String
    let blockchain: String
    let name: String
    let caip2id: String
    //Only for EVM
    let chainId: UInt?
    let nativeCurrency: CurrencyData
    let explorer: ExplorerData
    
    enum CodingKeys: String, CodingKey {
        case id
        case blockchain
        case name
        case caip2id
        case chainId = "chain_id"
        case nativeCurrency = "native_currency"
        case explorer
    }
    
}

struct ExplorerData: Codable {
    let name: String
    let url: URL
    let transactionPath: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case url
        case transactionPath = "transaction_path"
    }
}
