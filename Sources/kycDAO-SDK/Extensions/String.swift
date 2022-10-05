//
//  String.swift
//  
//
//  Created by Vekety Robin on 2022. 08. 18..
//

import Foundation

extension String {
    
    var asURL: URL? {
        URL(string: self)
    }
    
}
