//
//  ArraySlice.swift
//
//
//  Created by Vekety Robin on 2023. 01. 06..
//

import Foundation

public extension ArraySlice {
    var asArray: [Element] {
        [Element](self)
    }
}
