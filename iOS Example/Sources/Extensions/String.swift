//
//  String.swift
//  iOS Example
//
//  Created by Vekety Robin on 2022. 12. 07..
//

import Foundation
import UIKit

extension String {
    
    func font(size: CGFloat, weight: UIFont.Weight) -> NSMutableAttributedString {
        
        let attrString = NSMutableAttributedString(string: self)
        
        attrString.addAttributes([
            .font : UIFont.systemFont(ofSize: size, weight: weight)
        ])
        
        return attrString
    }
    
    func font(_ font: UIFont) -> NSMutableAttributedString {
        
        let attrString = NSMutableAttributedString(string: self)
        
        attrString.addAttributes([
            .font : font
        ])
        
        return attrString
        
    }
    
    func textColor(_ color: UIColor) -> NSMutableAttributedString {
        
        let attrString = NSMutableAttributedString(string: self)
        
        attrString.addAttributes([
            .foregroundColor: color
        ])
        
        return attrString
        
    }
    
}

