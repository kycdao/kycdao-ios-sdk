# Bring Your Own Node

Use your own RPC URLs to handle network calls

## Overview

The article provides you with details on how you can use your own RPC URLs instead of relying on the defaults used automatically by the library. There are two main ways the library interacts with custom RPCs: 
- through objects conforming to the ``WalletSessionProtocol``
- using ``NetworkOptions`` data

## For DApps


### Custom RPC for the verification

For every network you wish to have a connection to through your RPC, you have to add that network - RPC pair to ``WalletConnectManager``. This will make sure that every wallet session will be initialized to use the RPC you provided. 

Setting the RPC is done by calling ``WalletConnectManager/setRPCURL(_:forChain:)``. Chain is a [CAIP-2 format](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md) chain id.

```swift
WalletConnectManager.shared.setRPCURL(URL(string: "https://your.node/some/thing")!, 
                                      forChain: "eip155:80001")
```

> Note: You should set your RPC settings for ``WalletConnectManager`` at app launch, or at least before you call ``WalletConnectManager/startListening()`` first.

### Custom RPC for token validity check

#### Method 1: Use WalletSession

Since you have two methods to check token validity, one of which accepts ``WalletSessionProtocol``, you can use the same ``WalletConnectManager/setRPCURL(_:forChain:)`` function discussed above to set the URL and then pass your ``WalletConnectSession`` as a parameter to ``KYCManager/hasValidToken(verificationType:walletAddress:walletSession:)``

#### Method 2: Use NetworkOptions

```swift
let networkOptions = NetworkOptions(chainId: "eip155:80001", 
                                    rpcURL: URL(string: "https://your.node/some/thing")!)

let hasValidToken = try await KYCManager.shared.hasValidToken(verificationType: .kyc,
                                                              walletAddress: walletAddress,
                                                              networkOptions: networkOptions)
```

## For Wallets

### Custom RPC for the verification

When conforming to ``WalletSessionProtocol``, you have the option to return an RPC URL with the ``WalletSessionProtocol/rpcURL`` property.
``KYCSession`` will use your provided RPC after you create one with your `WalletSession` object.

### Custom RPC for token validity check

You have the same options here as during the DApp integration

#### Method 1: Use WalletSession

Call ``KYCManager/hasValidToken(verificationType:walletAddress:walletSession:)`` and pass your `WalletSession` object in, which should have a ``WalletSessionProtocol/rpcURL`` property having your RPC URL set.

#### Method 2: Use NetworkOptions

```swift
let networkOptions = NetworkOptions(chainId: "eip155:80001", 
                                    rpcURL: URL(string: "https://your.node/some/thing")!)

let hasValidToken = try await KYCManager.shared.hasValidToken(verificationType: .kyc,
                                                              walletAddress: walletAddress,
                                                              networkOptions: networkOptions)
```
