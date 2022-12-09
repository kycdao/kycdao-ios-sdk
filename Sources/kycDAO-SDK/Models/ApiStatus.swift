//
//  ApiStatus.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

struct ApiStatus: Codable {
    let persona: PersonaStatus?
    let smartContractsInfo: [SmartContractConfig]
    
    enum ApiStatusKeys: String, CodingKey{
        case persona = "persona"
        case smartContractsInfo = "smart_contracts_info"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ApiStatusKeys.self)
        self.persona = try container.decodeIfPresent(PersonaStatus.self, forKey: .persona)
        
        //Swift does not encode/decode raw representable enums correctly into/from dictionaries, manual encode/decode is needed
        //https://forums.swift.org/t/json-encoding-decoding-weird-encoding-of-dictionary-with-enum-values/12995/10
        let networkDict = try container.decode([String: [String : SmartContractConfigDTO]].self,
                                               forKey: .smartContractsInfo)
        
        let parsedSmartContractInfoDict = networkDict.reduce([:])
            { (partialNetworkResult: [String: [VerificationType: SmartContractConfigDTO]], networkEntry: (String, [String: SmartContractConfigDTO])) in
            
                var networkResult = partialNetworkResult
                let network = networkEntry.0
                    
                networkResult[network] = networkEntry.1.reduce([:])
                    { (partialVerificationTypeResult: [VerificationType: SmartContractConfigDTO], verificationTypeEntry: (String, SmartContractConfigDTO)) in
                    
                        var verificationTypeResult = partialVerificationTypeResult
                        if let verificationType = VerificationType(rawValue: verificationTypeEntry.0) {
                            verificationTypeResult[verificationType] = verificationTypeEntry.1
                        }
                        
                        return verificationTypeResult
                                                              
                    }
                
                return networkResult
            
        }
        
        //Convert nested dictionary to actual object
        self.smartContractsInfo = parsedSmartContractInfoDict.flatMap { network, value in
            value.map { verificationType, dto in
                return SmartContractConfig(address: dto.address,
                                           paymentDiscountPercent: dto.payment_discount_percent,
                                           verificationType: verificationType,
                                           network: network)
            }
        }
    }
}

struct PersonaStatus: Codable {
    let template_id: String?
    let sandbox: Bool?
}

struct SmartContractConfig: Codable, Equatable {
    let address: String
    let paymentDiscountPercent: Int
    let verificationType: VerificationType
    let network: String
}

struct SmartContractConfigDTO: Codable {
    let address: String
    let payment_discount_percent: Int
}
