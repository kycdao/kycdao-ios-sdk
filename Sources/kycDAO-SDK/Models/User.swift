//
//  User.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

struct UserDTO: Decodable {
    let id: Int
    let ext_id: String?
    let email: String?
    let email_confirmed: String?
    let residency: String?
    let blockchain_accounts: [BlockchainAccountDetails]?
    let disclaimer_accepted: String?
    let legal_entity: Bool?
    let verification_requests: [VerificationRequestData]?
    let available_images: [String: TokenImageDTO]
    let subscription_expiry: Date?
    
    enum CodingKeys: CodingKey {
        case id
        case ext_id
        case email
        case email_confirmed
        case residency
        case blockchain_accounts
        case disclaimer_accepted
        case legal_entity
        case verification_requests
        case available_images
        case subscription_expiry
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.ext_id = try container.decodeIfPresent(String.self, forKey: .ext_id)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.email_confirmed = try container.decodeIfPresent(String.self, forKey: .email_confirmed)
        self.residency = try container.decodeIfPresent(String.self, forKey: .residency)
        self.blockchain_accounts = try container.decodeIfPresent([BlockchainAccountDetails].self, forKey: .blockchain_accounts)
        self.disclaimer_accepted = try container.decodeIfPresent(String.self, forKey: .disclaimer_accepted)
        self.legal_entity = try container.decodeIfPresent(Bool.self, forKey: .legal_entity)
        self.verification_requests = try container.decodeIfPresent([VerificationRequestData].self, forKey: .verification_requests)
        self.available_images = try container.decode([String : TokenImageDTO].self, forKey: .available_images)
        
        let expiryString = try container.decodeIfPresent(String.self, forKey: .subscription_expiry)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        
        guard let expiryString else {
            self.subscription_expiry = nil
            return
        }
        
        let expiryDate = dateFormatter.date(from: expiryString)
        self.subscription_expiry = expiryDate
    }
}

struct User: Equatable {
    let id: Int
    let extId: String?
    let email: String?
    let emailConfirmed: String?
    let residency: String?
    let blockchainAccounts: [BlockchainAccountDetails]?
    let disclaimerAccepted: String?
    let legalEntity: Bool?
    let verificationRequests: [VerificationRequest]?
    let availableImages: [TokenImage]
    let subscriptionExpiry: Date?
    
    init(dto: UserDTO) {
        self.id = dto.id
        self.extId = dto.ext_id
        self.email = dto.email
        self.emailConfirmed = dto.email_confirmed
        self.residency = dto.residency
        self.blockchainAccounts = dto.blockchain_accounts
        self.disclaimerAccepted = dto.disclaimer_accepted
        self.legalEntity = dto.legal_entity
        self.verificationRequests = dto.verification_requests?.map { (verificationRequestData: VerificationRequestData) in
            VerificationRequest(id: verificationRequestData.id,
                                userId: verificationRequestData.user_id,
                                verificationType: verificationRequestData.verification_type,
                                status: verificationRequestData.status.simplified)
        }
        self.availableImages = dto.available_images.map { key, value in
            if let userId = dto.ext_id {
                return TokenImage(id: key,
                                  imageType: value.image_type,
                                  url: (value.url + "?user_id=\(userId)").asURL)
            } else {
                return TokenImage(id: key,
                                  imageType: value.image_type,
                                  url: value.url.asURL)
            }
        }
        self.subscriptionExpiry = dto.subscription_expiry
    }
}

struct BlockchainAccountDetails: Codable, Equatable {
    let id: Int
    let blockchain: Blockchain?
    let address: String?
    let tokens: [Token]
}

enum Blockchain: String, Codable {
    case ethereum = "Ethereum"
    case near = "Near"
}

struct Token: Codable, Equatable {
    let id: Int
    let network: String
    let authorization_code: String?
    let authorization_tx_id: String?
    let verification_type: VerificationType
    let minting_tx_id: String?
    let token_id: String?
}

