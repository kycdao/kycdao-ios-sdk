//
//  Configuration.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

/// A set of configuration options to initialize the kycDAO SDK
public struct Configuration {
    
    /// Selected environment to use
    public let environment: KycDaoEnvironment
    
    /// Network related configurations
    public let networkConfigs: [any NetworkConfigProtocol]
    
    /// Creates a configuration
    /// - Parameters:
    ///   - environment: Selected environment to use
    ///   - networkConfigs: Network related configurations
    public init(
//        apiKey: String,
        environment: KycDaoEnvironment,
        networkConfigs: [any NetworkConfigProtocol] = []
    ) {
//        self.apiKey = apiKey
        self.environment = environment
        self.networkConfigs = networkConfigs
    }
}

/// The environments the SDK supports
public enum KycDaoEnvironment: Decodable {
    
    /// A production, live service environment
    case production
    /// A developer service environment
    case dev
    
    var serverURL: URL {
        switch self {
        case .production:
            return URL(string: "https://kycdao.xyz")!
        case .dev:
            return URL(string: "https://staging.kycdao.xyz")!
        }
    }
    
    var demoMode: Bool {
        switch self {
        case .production:
            return false
        case .dev:
            return true
        }
    }
}

/// A set of configurations for any chain
///
/// You can create an `enum` that conforms to it or use ``KycDao/NetworkConfig`` instead
public protocol NetworkConfigProtocol: Hashable, Identifiable, Decodable {
    
    /// [CAIP-2](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md) chain id
    var chainId: String { get }
    
    /// RPC URL used for communicating with the chain.
    ///
    /// Leave it `nil` to use our default RPC URLs or provide your own RPC URL to use
    var rpcURL: URL? { get }
    
}

public extension NetworkConfigProtocol {
    
    /// ID of the network option, same as chainId
    var id: String {
        chainId
    }
}

/// A set of configurations for any chain
public struct NetworkConfig: NetworkConfigProtocol {
    
    /// ID of the network option, same as chainId
    public var id: String {
        chainId
    }
    
    /// [CAIP-2](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md) Chain ID
    public let chainId: String
    
    /// RPC URL used for communicating with the chain
    ///
    /// Leave it `nil` to use our default RPC URLs or provide your own RPC URL to use
    public let rpcURL: URL?
    
    /// Creates a configuration
    /// - Parameters:
    ///   - chainId: [CAIP-2](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md) chain id
    ///   - rpcURL: An RPC URL,  leave it `nil` to use our default RPC URLs or provide your own RPC URL to use
    public init(chainId: String, rpcURL: URL? = nil) {
        self.chainId = chainId
        self.rpcURL = rpcURL
    }
}

internal enum DefaultNetworkConfig: Hashable, Identifiable, CaseIterable {
    
    var id: String {
        chainId
    }
    
    case celoMainnet
    case celoAlfajores
    case polygonMainnet
    case polygonMumbai
    
    public var chainId: String {
        switch self {
        case .celoMainnet:
            return "eip155:42220"
        case .celoAlfajores:
            return "eip155:44787"
        case .polygonMainnet:
            return "eip155:89"
        case .polygonMumbai:
            return "eip155:80001"
        }
    }
    
    public var rpcURL: URL {
        switch self {
        case .celoMainnet:
            return URL(string: "https://forno.celo.org")!
        case .celoAlfajores:
            return URL(string: "https://alfajores-forno.celo-testnet.org")!
        case .polygonMainnet:
            return URL(string: "https://polygon-rpc.com")!
        case .polygonMumbai:
            return URL(string: "https://rpc-mumbai.maticvigil.com")!
        }
    }
    
    var asAppliedNetworkConfig: AppliedNetworkConfig {
        AppliedNetworkConfig(chainId: chainId,
                             rpcURL: rpcURL)
    }
}

/// A set of options for any chain
internal struct AppliedNetworkConfig: Hashable, Identifiable {
    
    var id: String {
        chainId
    }
    
    let chainId: String
    let rpcURL: URL
    
    init(chainId: String, rpcURL: URL) {
        self.chainId = chainId
        self.rpcURL = rpcURL
    }
}
