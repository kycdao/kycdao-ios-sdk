//
//  Precondition.swift
//  
//
//  Created by Vekety Robin on 2023. 01. 04..
//

import Foundation

func precondition<T: Error>(_ condition: @autoclosure () -> (Bool), throws error: T) throws {
    if !condition() {
        throw error
    }
}
