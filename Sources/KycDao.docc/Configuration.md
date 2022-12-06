# Configuring the SDK

Learn how to make the required configurations or customize the SDK for your needs before you use it.

## Overview

In order to use the kycDAO iOS SDK, you must provide certain configurations before using it. Currently only an environment configuration is mandatory but an api key will be required in the near future as well. There are optional configurations, like setting custom RPC URLs to use with your supported networks.

## Environment types

``KycDaoEnvironment`` `enum` defines the available environments.

``KycDaoEnvironment`` | Implementation
--- | ---
``KycDaoEnvironment/production`` | A live, production environment which uses the smart contracts on the main nets, with a live identity verification service and live kycDAO server environment.
``KycDaoEnvironment/dev`` | A developer environment which uses the smart contracts on the dev/test nets, with a sandbox identity verification service and staging kycDAO server environment.

## Network configurations

``NetworkConfigProtocol`` describes a set of configurations for a particular network. You have the option to use ``NetworkConfig`` which already conforms to the protocol. This is useful when you plan with a small number of networks that you support and the number is not expected to grow over time. 

```swift
// Creates a network config, which sets the RPC URL used 
// by Mumbai testnet calls to `https://matic-mumbai.chainstacklabs.com`
let mumbaiConfig = NetworkConfig(chainId: "eip155:80001",
                                 rpcURL: URL(string: "https://matic-mumbai.chainstacklabs.com"))
```

If you want to support multiple networks and want extensibility, use ``NetworkConfigProtocol`` and conform to it using an `enum`.

```swift
enum CustomNetworkConfig: NetworkConfigProtocol, CaseIterable {
    
    var id: String {
        chainId
    }

    case polygonMainnet
    case polygonMumbai
    
    public var chainId: String {
        switch self {
        case .polygonMainnet:
            return "eip155:89"
        case .polygonMumbai:
            return "eip155:80001"
        }
    }
    
    public var rpcURL: URL? {
        switch self {
        case .polygonMainnet:
            return URL(string: "https://polygon-rpc.com")!
        case .polygonMumbai:
            return URL(string: "https://matic-mumbai.chainstacklabs.com")!
        }
    }
    
}
```

> Tip: If you make the `enum` a `CaseIterable` type, you can easily create a list of all your configurations by calling `CustomNetworkConfig.allCases`.

## Setting your configurations

You can set the configurations by calling ``VerificationManager/configure(_:)``. 

> Important: You have to call it exactly **once** per app launch. Calling it multiple times won't overwrite the previous configuration.

First create the configuration like

```swift
let networkConfigs = [NetworkConfig(chainId: "eip155:89",
                                    rpcURL: URL(string: "https://polygon-rpc.com")),
                      NetworkConfig(chainId: "eip155:80001",
                                    rpcURL: URL(string: "https://matic-mumbai.chainstacklabs.com"))]

let configuration = Configuration(environment: .dev,
                                  networkConfigs: networkConfigs)
```

or

```swift
let configuration = Configuration(environment: .dev,
                                  networkConfigs: CustomNetworkConfig.allCases)
```

then call

```swift
VerificationManager.configure(configuration)
```


