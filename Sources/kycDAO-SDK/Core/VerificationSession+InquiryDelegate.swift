//
//  File.swift
//  
//
//  Created by Vekety Robin on 2023. 01. 11..
//

import Foundation
import Persona2

extension VerificationSession: InquiryDelegate {
    
    public func inquiryComplete(inquiryId: String, status: String, fields: [String : InquiryField]) {
        print("Persona completed")
        personaSessionData = nil
        identificationContinuation?.resume(returning: .completed)
        identificationContinuation = nil
    }
    
    public func inquiryCanceled(inquiryId: String?, sessionToken: String?) {
        print("Persona canceled")
        
        if let inquiryId, let sessionToken, let referenceId = sessionData.user?.extId {
            personaSessionData = PersonaSessionData(referenceId: referenceId, inquiryId: inquiryId, sessionToken: sessionToken)
        }
        
        identificationContinuation?.resume(returning: .cancelled)
        identificationContinuation = nil
    }
    
    public func inquiryError(_ error: Error) {
        print("Inquiry error")
        personaSessionData = nil
        identificationContinuation?.resume(throwing: KycDaoError.persona(error))
        identificationContinuation = nil
    }
    
}
