//
//  VerificationRequest.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

enum VerificationStatusDTO: String, Decodable {
    case created = "Created"
    case failed = "Failed"
    case inReview = "InReview"
    case verified = "Verified"
    case notVerified = "NotVerified"
    
    var simplified: VerificationStatus {
        switch self {
        case .verified:
            return .verified
        case .inReview:
            return .processing
        case .notVerified, .failed, .created:
            return .notVerified
        }
    }
}

struct VerificationRequestData: Decodable, Equatable {
    let id: Int
    let user_id: Int
    let verification_type: VerificationType
    let status: VerificationStatusDTO
}

struct VerificationRequest: Decodable, Equatable {
    let id: Int
    let userId: Int
    let verificationType: VerificationType
    let status: VerificationStatus
}
