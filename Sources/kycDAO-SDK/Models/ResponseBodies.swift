//
//  ResponseBodies.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

struct MintAuthorizationDTO: Decodable {
    let token: TokenDetailsDTO?
}

struct TokenDetailsDTO: Decodable {
    let image_url: String?
    let authorization_code: String?
    let authorization_tx_id: String?
}

struct TokenImageDTO: Decodable {
    let image_type: TokenImageType
    let url: String
}
