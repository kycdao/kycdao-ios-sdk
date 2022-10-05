//
//  WalletConnectModels.swift
//  
//
//  Created by Vekety Robin on 2022. 07. 04..
//

import Foundation
import WalletConnectSwift
import BigInt

public typealias WCSession = WalletConnectSwift.Session

struct ListingsDTO: Decodable {
    let listings: [String: ListingDTO]?
    let count: Int?
}

struct ListingDTO: Decodable {
    let id: String
    let name: String?
    let image_url: ImageURLDTO?
    let mobile: MobileDTO?
    let chains: [String]? //Format: "eip155:1"
}

struct ImageURLDTO: Decodable {
    let sm: String?
    let md: String?
    let lg: String?
}

struct MobileDTO: Decodable {
    let native: String?
    let universal: String?
}

public struct Wallet: Identifiable, Hashable, Codable {
    public let id: String
    public let name: String
    public let imageURL: URL?
    public let universalLinkBase: String?
    public let deepLinkBase: String?
}

struct PendingSession: Codable {
    let url: WCURL
    var wallet: Wallet?
    
    var walletId: String? {
        wallet?.id
    }
    
    var state: ConnectionState
}

enum ConnectionState: Codable, Equatable, Hashable {
    case connected
    case retrying(retries: Int = 3)
    case failed
    case initialised
}

enum SessionStatus: Codable {
    case active
    case inactive
}
