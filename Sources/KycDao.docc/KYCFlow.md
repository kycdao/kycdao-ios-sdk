# Implementing the KYC flow

A guide for KYC verification and NFT minting

## Overview

This guide will help you implementing the whole process of minting a kycDAO NFT.
The process consists of the following steps:
1. Login to kycDAO with your wallet
2. Make the user accept the disclaimer
3. Gather some personal information from the user
4. Confirm email
5. Persona verification
6. Select NFT image to mint
7. Mint NFT

The user can end up at almost any point of the KYC process. It is important to manage that users may interrupt the KYC process and return later to complete the flow. You can determine the next step of the user using various state properties of the ``KYCSession``, for example ``KYCSession/disclaimerAccepted`` or ``KYCSession/requiredInformationProvided``. Keep in mind that y

### Requirements

Before you can implement the KYC flow, you must follow either the <doc:DAppIntegration> guide for DApps or the <doc:WalletIntegration> guide.

## Login

Once you obtained a KYCSession as shown in <doc:DAppIntegration> and <doc:WalletIntegration> guide, you can login your wallet to that session.

```swift
try await kycSession.login()
```

## Accepting the disclaimer

The user has to accept the disclaimer before being able to interact with kycDAO services.

```swift
if !kycSession.disclaimerAccepted {
    try await kycSession.acceptDisclaimer()
}
```

## Gathering personal information

Check wether this step was already completed by the user by reading the value of ``KYCSession/requiredInformationProvided``
If the user did not have all the required information, you should gather it and submit, but first of all, you have to accept the disclaimer, if it is not accepted yet

```swift
if !kycSession.requiredInformationProvided {
    //Residency is in ISO 3166-2
    let personalData = PersonalData(email: "example@email.com",
                                    residency: "US",
                                    legalEntity: false)
    try await kycSession.setPersonalData(personalData)
}
```

### 
