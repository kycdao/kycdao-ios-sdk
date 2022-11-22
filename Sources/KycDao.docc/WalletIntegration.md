# Wallet Integration
Wallet integration guide


## Overview

This article provides a guide for integrating the SDK into a wallet app. 

Three main topics will be discussed here:
- Handle wallet related tasks
- Checking the KYC status of an address
- Starting the KYC flow

## Handle wallet related tasks

The SDK requires that it has access to wallet related data and functions. ``WalletSessionProtocol`` describes a communication session with your wallet, where these function and data requirements are defined. You have to create a conforming class to this protocol and provide an implementation of the signing and minting functions.

### Conforming to WalletSessionProtocol

Properties | Implementation
--- | ---
``WalletSessionProtocol/id`` | A unique identifier for your session, assigning `UUID().uuidString` to this property at the initialization of your implementation should be enough.
``WalletSessionProtocol/chainId`` | The ID of the chain used specified in [CAIP-2 format](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md). For example `eip155:1` is the `chainId` of Ethereum Mainnet.
``WalletSessionProtocol/rpcURL`` | A custom RPC URL you whish to use during on-chain calls. Make sure your custom RPC uses the same chain you provided the `chainId` for. By returning `nil` for `rpcURL`, the SDK will default to using its own RPC for the given chain.

#### Functions

``WalletSessionProtocol/personalSign(walletAddress:message:)``

In the implementation of this function your wallet is expected to sign a message (for EVM chains use the personal_sign call), with the given wallet address. The return value of this function should be the signed message. 

``WalletSessionProtocol/sendMintingTransaction(walletAddress:mintingProperties:)``

In the implementation of this function your wallet is expected to send a transaction (for EVM chains use eth_sendTransaction call), with the given wallet address using the minting properties.

## Checking the KYC status of an address

A ``NetworkOptions`` object have to be constructed specifying the chain in CAIP-2 format and an RPC URL can be optionally provided, read more about it **here**.

```swift
let networkOptions = NetworkOptions(chainId: "eip155:80001")
let hasValidToken = try await KYCManager.shared.hasValidToken(verificationType: .kyc,
                                                              walletAddress: walletAddress,
                                                              networkOptions: networkOptions)
```

## Starting the KYC flow

First you need to have an instance of an object you created at the *'Conforming to WalletSessionProtocol'* section. Once you obtained your wallet session instance, pass it along with a wallet address to ``KYCManager/createSession(walletAddress:walletSession:)``

```swift
let walletSession: WalletSessionProtocol = ...
let kycSession = try await KYCManager.shared.createSession(walletAddress: selectedAccount,
                                                           walletSession: walletSession)
```

## Implementing the KYC flow

The KYC flow is the same for DApps and Wallets. It is covered in a common article:

<doc:KYCFlow>
