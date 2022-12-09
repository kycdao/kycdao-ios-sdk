//
//  File.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

struct ChainAndAddressDTO: Encodable {
    let blockchain: String
    let address: String
}

struct SignatureDTO: Encodable {
    let signature: String
    let public_key: String?
}

struct MintRequestDTO: Encodable {
    let blockchain_account_id: Int
    let network: String
    let selected_image_id: String
    let verification_type: VerificationType
    let subscription_duration: String
    
    init(accountId: Int, network: String, selectedImageId: String, subscriptionDuration: UInt32, verificationType: VerificationType = .kyc) {
        self.blockchain_account_id = accountId
        self.network = network
        self.selected_image_id = selectedImageId
        self.verification_type = verificationType
        //ISO 8601 formatted single year input 'PnY' where 'n' is the number of years
        self.subscription_duration = "P\(subscriptionDuration)Y"
    }
}

struct MintResultUploadDTO: Codable {
    
    let authorization_code: String
    let token_id: String
    let minting_tx_id: String
    
    init(authCode: String, tokenId: String, txHash: String) {
        authorization_code = authCode
        token_id = tokenId
        minting_tx_id = txHash
    }
    
}
