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

> Tip: You can build, use and view this documentation in Xcode locally once you have the SDK added to your project.

### Source

The source code of the SDK is on [GitHub](https://github.com/kycdao/kycdao-ios-sdk/).

### Example

An example Xcode project for a DApp implementation is available on the [iOS GitHub repository](https://github.com/kycdao/kycdao-ios-sdk/tree/main/iOS%20Example).

> Important: It is recommended that you bring your own nodes when using the SDK, you can check the <doc:ConfigureSDK> article to see how to set your own RPC URLs for your supported networks.

### Supported networks

Main | Test
--- | ---
Polygon | Polygon Mumbai
Celo | Celo Alfajores


### Other platforms

The mobile SDK is also available on [Android](https://docs.kycdao.xyz/buidl/sdks/mobilesdk/android-sdk/) and [React Native](https://docs.kycdao.xyz/buidl/sdks/mobilesdk/react-native-sdk/)

For web based solutions check out the [UI](https://docs.kycdao.xyz/buidl/sdks/uisdk/) or the [Core SDK](https://docs.kycdao.xyz/buidl/sdks/coresdk/)

You can learn about [smart contract gating here](https://docs.kycdao.xyz/buidl/smartcontractgating/)

## Topics

### Articles

- <doc:Installation>
- <doc:ConfigureSDK>
- <doc:DAppIntegration>
- <doc:WalletIntegration>
- <doc:Onboarding>

### Verification

- ``VerificationManager``
- ``VerificationSession``
- ``WalletSessionProtocol``

### WalletConnect

- ``WalletConnectManager``
- ``WalletConnectSession``
- ``Wallet``
