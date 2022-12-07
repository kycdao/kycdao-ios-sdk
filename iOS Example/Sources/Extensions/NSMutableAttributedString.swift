//
//  NSMutableAttributedString.swift
//  iOS Example
//
//  Created by Vekety Robin on 2022. 12. 07..
//

import Foundation
import UIKit

protocol NSAttributedStringValueType { }
extension UIColor : NSAttributedStringValueType { }
extension UIFont : NSAttributedStringValueType { }

extension NSMutableAttributedString {
    
    func addAttributes(_ attrs: [NSAttributedString.Key: NSAttributedStringValueType]) {
        addAttributes(attrs, range: NSRange(location: 0, length: string.count))
    }
    
    static func +(lhs: NSMutableAttributedString, rhs: NSAttributedString) -> NSMutableAttributedString {
        
        lhs.append(rhs)
        
        return lhs
    }
    
    static func +(lhs: String, rhs: NSMutableAttributedString) -> NSMutableAttributedString {
        
        let attributedString = NSMutableAttributedString(string: lhs)
        attributedString.append(rhs)
        
        return attributedString
    }
    
    static func +(lhs: NSMutableAttributedString, rhs: String) -> NSMutableAttributedString {
        
        let attributedString = NSMutableAttributedString(string: rhs)
        lhs.append(attributedString)
        
        return lhs
    }
    
}
