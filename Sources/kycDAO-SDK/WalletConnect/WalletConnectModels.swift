//
//  WalletConnectModels.swift
//  
//
//  Created by Vekety Robin on 2022. 07. 04..
//

import Foundation
import WalletConnectSwift
import BigInt

typealias WCSession = WalletConnectSwift.Session

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

/// A model that describes a wallet for the SDK usable with WalletConnect.
/// The data provided in the model is derived from the [WalletConnect V1 registry](https://registry.walletconnect.com/api/v1/wallets)
public struct Wallet: Identifiable, Hashable, Codable {
    /// A unique id of the wallet
    public let id: String
    /// Name of the wallet app
    public let name: String
    /// An url pointing to an icon image of the wallet app
    public let imageURL: URL?
    internal let universalLinkBase: String?
    internal let deepLinkBase: String?
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
