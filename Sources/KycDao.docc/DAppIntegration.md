# DApp and Web2 Integration
DApp and Web2 integration guide

## Overview

This article provides a guide for integrating the SDK into an app that is not a wallet. Signing and minting will be performed by a separate wallet app, which will have to be connected to the SDK. For this task, the SDK uses WalletConnect.

Three main topics will be discussed here:
- Connecting to a wallet
- Checking the KYC status of an address
- Initializing a KYC flow

## Connecting to a wallet

Connecting to a wallet starts with the ``WalletConnectManager`` having to actively listen for peers (wallets) which will accept our session offer.

```swift
WalletConnectManager.shared.startListening()
```

The ``WalletConnectManager`` will keep waiting for new connections and emit ``WalletConnectSession`` objects on successful connections. We can subscribe for these session creation events using

```swift
WalletConnectManager.shared.sessionStarted
    .receive(on: DispatchQueue.main)
    .sink { [weak self] walletConnectSession in
        //Do something with walletConnectSession
    }.store(in: &disposeBag)
```

You have two options to connect your user's wallet to the kycDAO SDK:
- Present them a QR Code they can scan
- Show them a list of supported wallet apps, where they can manually select their own

### Connecting through QR Code

The QR Code for WalletConnect is an URI. This URI will change over time: ``WalletConnectSession`` creation or rejection will result in the URI being refreshed, awaiting new connections on the new URI.

```swift
WalletConnectManager.shared.pendingSessionURI
    .receive(on: DispatchQueue.main)
    .sink { [weak self] uri in
        self?.setQR(uri)
    }.store(in: &disposeBag)
```

This is a possible implementation of how you could create an image from any `String` and add it to an `UIImageView`

```swift
func setQR(_ code: String) {
    let data = Data(code.utf8)
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.setValue(data, forKey: "inputMessage")

    guard let outputImage = filter.outputImage else {
        return
    }
    
    let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 4, y: 4))
    
    if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
        qrImageView.layer.magnificationFilter = CALayerContentsFilter.nearest
        qrImageView.image = UIImage(cgImage: cgImage)
    }
}
```

Once the user scans the QR in their wallet and accepts the connection, ``WalletConnectManager/sessionStarted`` will emit the session object of the connection and ``WalletConnectManager/pendingSessionURI`` will emit the URI for the next possible connection.

### Connecting through the wallet app list

To get a list of supported wallets you should call
```swift
let wallets = try await WalletConnectManager.listWallets()
```
which returns an array of ``Wallet`` models.
You can display the image and name of these wallets, let the user select their preferred wallet, then
```swift
try WalletConnectManager.shared.connect(withWallet: selectedWallet)
```

Once the wallet is launched and the user accepts the connection, ``WalletConnectManager/sessionStarted`` will emit the session object of the connection and ``WalletConnectManager/pendingSessionURI`` will emit the URI for the next possible connection.

## Check KYC status of an address

Depending from your usecase, you have two options.

If you already obtained the user's wallet address and know the chain they possibly minted their KYC NFT on, you should

If the user's wallet address is unknown, you can get a connection through WalletConnectManager to their wallet and use the WalletConnectSession object to ask for their KYC status.

### Using WalletConnectSession

``WalletConnectSession`` contains a blockchain account list (wallet addresses), with all the accounts returned by WalletConnect for the connection with the wallet app. The user should select their address from ``WalletConnectSession/accounts`` if there are more than one, otherwise the one available address can be used.

Once we obtained the wallet address, we can call

```swift
let hasValidToken = try await KYCManager.shared.hasValidToken(verificationType: .kyc,
                                                              walletAddress: selectedAddress,
                                                              walletSession: walletConnectSession)
```

### Using existing wallet information

A ``NetworkOptions`` object have to be constructed specifying the chain in [CAIP-2 format](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md) format and an RPC URL can be optionally provided, read more about it **here**.

```swift
let networkOptions = NetworkOptions(chainId: "eip155:80001")
let hasValidToken = try await KYCManager.shared.hasValidToken(verificationType: .kyc,
                                                              walletAddress: walletAddress,
                                                              networkOptions: networkOptions)
```

## Starting the KYC flow

First you need to have a ``WalletConnectSession`` and a selected wallet address from ``WalletConnectSession/accounts``. 

```swift
let kycSession = try await KYCManager.shared.createSession(walletAddress: selectedAccount,
                                                           walletSession: walletConnectSession)
```

## Implementing the KYC flow

The KYC flow is the same for DApps and Wallets. It is covered in a common article:

<doc:KYCFlow>

## Summary

An implementation of this article's content should look similar to this in terms of the logical flow of things:

```swift

init() {

    let walletConnectManager = WalletConnectManager.shared

    walletConnectManager.pendingSessionURI
        .receive(on: DispatchQueue.main)
        .sink { [weak self] uri in
            self?.setQR(uri)
        }.store(in: &disposeBag)

    walletConnectManager.sessionStarted
        .receive(on: DispatchQueue.main)
        .sink { [weak self] walletConnectSession in
            self?.sessionReceived(walletConnectSession)
        }.store(in: &disposeBag)

    Task {
        let wallets = try await WalletConnectManager.listWallets()
        //Add wallets to your datasource, populate the UI
    }

    walletConnectManager.startListening()

}

func selectWallet(wallet: Wallet) {

    try WalletConnectManager.shared.connect(withWallet: wallet)

}

func sessionReceived(_ walletConnectSession: WalletConnectSession) {

    //Accounts array technically should never be empty
    guard !walletConnectSession.accounts.isEmpty else { 
        return
    }

    var walletAddress: String

    if walletConnectSession.accounts.count == 1,
       let account = walletConnectSession.accounts.first {
        //Use the only available account
        walletAddress = account
    } else {
        //Obtain the account from user selection
        walletAddress = ...
    }

    Task {
        let hasValidToken = try await KYCManager.shared.hasValidToken(verificationType: .kyc,
                                                                      walletAddress: walletAddress,
                                                                      walletSession: walletConnectSession)

        if hasValidToken {
            //continue with your logic, let the user access your service etc...
        } else {
            let kycSession = try await KYCManager.shared.createSession(walletAddress: walletAddress,
                                                                       walletSession: walletConnectSession)
            //Use KYCSession to coordinate the KYC flow...
        }
    }

}

```
