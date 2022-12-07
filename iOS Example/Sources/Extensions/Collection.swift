//
//  Collection.swift
//  iOS Example
//
//  Created by Vekety Robin on 2022. 12. 07..
//

import Foundation

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
