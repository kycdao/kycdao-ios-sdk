//
//  BigUInt.swift
//  
//
//  Created by Vekety Robin on 2022. 08. 11..
//

import Foundation
import BigInt

extension BigUInt {
    
    func decimalText(divisor: BigUInt) -> String {
        
        let result = self.quotientAndRemainder(dividingBy: divisor)
        let fullUnit = result.quotient
        let remainder = result.remainder
        
        let missingLeadingZeroCount = Swift.max((divisor.digits - remainder.digits) - 1, 0)
        
        var remainderText = "\(remainder)"
    
        //keep at least 3 digit accuracy after initial zeros
        if remainderText.count > 3 {
            remainderText = String(remainderText.dropLast(remainderText.count - 3))
        }
        
        if missingLeadingZeroCount > 0 {
            return "\(fullUnit)," + String(repeating: "0", count: missingLeadingZeroCount) + remainderText
        }
        
        return "\(fullUnit)"
        
    }
    
    var digits: Int {
        String(self).count
    }
    
    var eth: BigUInt {
        return self * BigUInt(10).power(18)
    }

    var gwei: BigUInt {
        return self * BigUInt(10).power(9)
    }
    
}
