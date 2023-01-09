# ``KycDao``

Composable Compliance

## Overview

iOS SDK of [kycDAO](https://kycdao.xyz/)

With the kycDAO iOS SDK you can 
- check whether a wallet address have been verified and has a valid token. 
- go through the verification process from identification till kycNFT minting.

The SDK can be used by
- Wallets
- DApps
- Web2 Applications

### Documentation

The documentation of the SDK is available [here](https://kycdao.github.io/kycdao-ios-sdk/documentation/kycdao/).

> Tip: You can build, use and view the documentation in Xcode locally once you have the SDK added to your project.

### Installation

#### Swift Package Manager

Use Xcode to add to the project (**File** -> **Swift Packages**):

```
https://github.com/kycdao/kycdao-ios-sdk
```

or add this to your `Package.swift` file:

```swift
.package(url: "https://github.com/kycdao/kycdao-ios-sdk", from: "0.1.0")
```

#### CocoaPods

Add KycDao to your Podfile:

```perl
pod 'KycDao'
```

Then run the following command:

```shell
$ pod install
```

#### Importing to source file

Add an import at the top of your source file

```swift
import KycDao
```

That's it. You can start coding.

### Configuration

Set up the environment and [Configure the SDK](https://kycdao.github.io/kycdao-ios-sdk/documentation/kycdao/configuresdk) for your needs

> Important: It is recommended that you bring your own nodes when using the SDK, you can check the [Configure SDK](https://kycdao.github.io/kycdao-ios-sdk/documentation/kycdao/configuresdk) article to see how to set your own RPC URLs for your supported networks.

### Example

An example Xcode project for a DApp implementation is available in the [iOS Example](https://github.com/kycdao/kycdao-ios-sdk/tree/main/iOS%20Example) folder.

### Integration

Learn the [Wallet Integration](https://kycdao.github.io/kycdao-ios-sdk/documentation/kycdao/walletintegration) or [DApp Integration](https://kycdao.github.io/kycdao-ios-sdk/documentation/kycdao/dappintegration) specific steps to use the SDK

Help your users getting verified by implementing the [Onboarding](https://kycdao.github.io/kycdao-ios-sdk/documentation/kycdao/onboarding) flow

Deep dive into the SDK by visiting the [API documentation](https://kycdao.github.io/kycdao-ios-sdk/documentation/kycdao)

### Supported networks

Main | Test
--- | ---
Polygon | Polygon Mumbai
Celo | Celo Alfajores


### Other platforms

The SDK is also available on other mobile platforms (Android, React Native) and Web. 
You can browse our available SDKs [here](https://docs.kycdao.xyz/)

You can learn about [smart contract gating here](https://docs.kycdao.xyz/smartcontracts/onchaingating/)
