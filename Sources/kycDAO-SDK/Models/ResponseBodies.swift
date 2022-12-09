//
//  ResponseBodies.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

struct MintAuthorizationDTO: Decodable {
    let code: String?
    let tx_hash: String?
}

struct TokenDetailsDTO: Decodable {
    let image_url: String?
}

struct TokenImageDTO: Decodable {
    let image_type: TokenImageType
    let url: String
}
