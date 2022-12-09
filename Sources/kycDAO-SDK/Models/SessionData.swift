//
//  SessionData.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

struct BackendSessionDataDTO: Decodable {
    let id: String
    let nonce: String
    var user: UserDTO?
    let discount_years: UInt32?
}

struct BackendSessionData: Equatable {
    let id: String
    let nonce: String
    var user: User?
    let discountYears: UInt32?
    
    init(dto: BackendSessionDataDTO) {
        self.id = dto.id
        self.nonce = dto.nonce
        if let dtoUser = dto.user {
            self.user = User(dto: dtoUser)
        }
        self.discountYears = dto.discount_years
    }
}
