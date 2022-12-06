# Wallet Integration
Wallet integration guide

## Overview

This article provides a guide for integrating the SDK into a wallet app. 

Three main topics will be discussed here:
- Handle wallet related tasks
- Checking the verification status of an address
- Initializing a verification flow

## Handle wallet related tasks

The SDK requires that it has access to wallet related data and functions. ``WalletSessionProtocol`` describes a communication session with your wallet, where these function and data requirements are defined. You have to create a conforming class to this protocol and provide an implementation of the signing and minting functions.

### Conforming to WalletSessionProtocol

Properties | Implementation
--- | ---
``WalletSessionProtocol/id`` | A unique identifier for your session, assigning `UUID().uuidString` to this property at the initialization of your implementation should be enough.
``WalletSessionProtocol/chainId`` | The ID of the chain used specified in [CAIP-2 format](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md). For example `eip155:1` is the `chainId` of Ethereum Mainnet.

#### Functions

``WalletSessionProtocol/personalSign(walletAddress:message:)``

In the implementation of this function your wallet is expected to sign a message (for EVM chains use the personal_sign call), with the given wallet address. The return value of this function should be the signed message. 

``WalletSessionProtocol/sendMintingTransaction(walletAddress:mintingProperties:)``

In the implementation of this function your wallet is expected to send a transaction (for EVM chains use eth_sendTransaction call), with the given wallet address using the minting properties.

## Checking the verification status of an address

### Using your WalletSessionProtocol implementation

You have to pass your `WalletSession` object to ``VerificationManager/hasValidToken(verificationType:walletAddress:walletSession:)`` along with a wallet address and verification type.

```swift
let hasValidToken = try await VerificationManager.shared.hasValidToken(verificationType: .kyc,
                                                                       walletAddress: selectedAddress,
                                                                       walletSession: walletSession)
```

### Using existing wallet information

When you already have the chain information of the user's wallet, you can use a chain id in [CAIP-2 format](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md) format to check for a valid token.

```swift
let chainId = "eip155:80001" // eip155:80001 is Polygon Mumbai
let hasValidToken = try await VerificationManager.shared.hasValidToken(verificationType: .kyc,
                                                                       walletAddress: walletAddress,
                                                                       chainId: chainId)
```

## Initializing a verification flow

First you need to have an instance of an object you created at the *'Conforming to WalletSessionProtocol'* section. 
Once you obtained your wallet session instance, pass it along with a wallet address to ``VerificationManager/createSession(walletAddress:walletSession:)``

```swift
let walletSession: WalletSessionProtocol = ...
let verificationSession = try await VerificationManager.shared.createSession(walletAddress: selectedAccount,
                                                                             walletSession: walletSession)
```

## Implementing the verification flow

The verification flow is the same for DApps and Wallets. It is covered in a common article:

<doc:Onboarding>
