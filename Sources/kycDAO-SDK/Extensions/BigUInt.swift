//
//  BigUInt.swift
//  
//
//  Created by Vekety Robin on 2022. 08. 11..
//

import Foundation
import BigInt

extension BigUInt {
    
    func decimalText(divisor: BigUInt, digitsAfterZeros: Int = 3) -> String {
        
        let result = self.quotientAndRemainder(dividingBy: divisor)
        let fullUnit = result.quotient
        let remainder = result.remainder
        
        let missingLeadingZeroCount = Swift.max((divisor.digits - remainder.digits) - 1, 0)
        
        var remainderText = "\(remainder)"
    
        //keep at least X digit accuracy after initial zeros
        if remainderText.count > digitsAfterZeros {
            remainderText = String(remainderText.dropLast(remainderText.count - digitsAfterZeros))
        }
        
        //drop unnecessary zeros from last digits, recursive
        func dropLastZeros(fromNumberText text: String) -> String {
            if text.last == "0" {
                return dropLastZeros(fromNumberText: String(text.dropLast(1)))
            }
            return text
        }
        
        remainderText = dropLastZeros(fromNumberText: remainderText)
        
        if missingLeadingZeroCount > 0 {
            return "\(fullUnit)," + String(repeating: "0", count: missingLeadingZeroCount) + remainderText
        }
        
        return "\(fullUnit)," + remainderText
        
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
