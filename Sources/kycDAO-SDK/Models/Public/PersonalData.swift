//
//  PersonalData.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

/// Personal data of the user
public struct PersonalData: Codable {
    
    /// Email address of the user
    public let email: String
    
    /// Country of residency of the user
    ///
    /// Contains the country of residency in [ISO 3166-2](https://en.wikipedia.org/wiki/ISO_3166-2) format.
    /// ##### Example
    /// ISO 3166-2 Code | Country name
    /// --- | ---
    /// `BE` | Belgium
    /// `ES` | Spain
    /// `FR` | France
    /// `US` | United States of America
    public let residency: String
    
    /// Legal entity status of the user
    public let isLegalEntity: Bool
    
    enum CodingKeys: String, CodingKey {
        case email
        case residency
        case isLegalEntity = "legal_entity"
    }
    
    ///
    /// - Parameters:
    ///   - email: Email address of the user
    ///   - residency: Country of residency of the user
    ///
    /// Country of residency is in [ISO 3166-2](https://en.wikipedia.org/wiki/ISO_3166-2) format.
    /// ##### Example
    /// ISO 3166-2 Code | Country name
    /// --- | ---
    /// `BE` | Belgium
    /// `ES` | Spain
    /// `FR` | France
    /// `US` | United States of America
    public init(email: String, residency: String) {
        self.email = email
        self.residency = residency
        self.isLegalEntity = false
    }
}
