# Onboarding

A guide for the verification process and NFT minting

## Overview

This guide will help you implementing the whole process of minting a kycDAO NFT.
The process consists of the following steps:
1. Login to kycDAO with your wallet
2. Make the user accept the disclaimer
3. Gather some personal information from the user
4. Confirm the email address
5. Verification
6. Select NFT image to mint
7. Mint NFT

The user can end up at almost any point of the verification process. It is important to manage that users may interrupt the process and return later to complete the flow. You can determine the next step of the user using various state properties of the ``VerificationSession``, for example ``VerificationSession/disclaimerAccepted``. Keep in mind that these values may change for an existing user. For example the disclaimer acceptance will be reseted if the contents of the disclaimer change and a new user consent is required.

### Requirements

Before you can implement the verification flow, you must follow either the <doc:DAppIntegration> guide for DApps or the <doc:WalletIntegration> guide.

## Login

Once you obtained a `VerificationSession` as shown in <doc:DAppIntegration> and <doc:WalletIntegration> guide, you can login your wallet to that session.

```swift
try await verificationSession.login()
```

## Accepting the disclaimer

The user has to accept the disclaimer before being able to interact with kycDAO services.

```swift
if !verificationSession.disclaimerAccepted {
    try await verificationSession.acceptDisclaimer()
}
```

## Gathering personal information

Check wether this step was already completed by the user by reading the value of ``VerificationSession/requiredInformationProvided``
If the user did not have all the required information, you should gather it and submit, but first of all, you have to accept the disclaimer, if it is not accepted yet

```swift
if !verificationSession.requiredInformationProvided {
    //Residency is in ISO 3166-2
    let personalData = PersonalData(email: "example@email.com",
                                    residency: "US",
                                    isLegalEntity: false)
    try await verificationSession.setPersonalData(personalData)
}
```

> Note: Calling ``VerificationSession/setPersonalData(_:)`` will send a confirmation email to the provided email address automatically, you are not required to call ``VerificationSession/sendConfirmationEmail()`` manually

## Confirm email

After you ``VerificationSession/setPersonalData(_:)``, you only need to wait for the email to be confirmed by the user to continue. 

If the user did not receive or lost the email, they may want to resend the confirmation email. You can use ``VerificationSession/sendConfirmationEmail()`` in this case.

```swift
try await verificationSession.sendConfirmationEmail()
```

To wait for email confirmation, call ``VerificationSession/resumeOnEmailConfirmed()``. It suspends the Task and resumes when the email becomes confirmed.

```swift
if !verificationSession.emailConfirmed {
    try await verificationSession.resumeOnEmailConfirmed()
}
```

## Verification

Verification is currently done through Persona. You can check whether the user already has an accepted verification using the property ``VerificationSession/verificationStatus``.

``VerificationSession/verificationStatus`` | Meaning
--- | ---
`verified` | The user was successfully verified
`processing` | The user is under verification
`notVerified` | The user is not verified (missing or rejected verification)

The Persona identity verification process will launch a modal, which has to be attached to a `UIViewController`. You can launch the identity process by calling

```swift
let status = try await verificationSession.startIdentification(fromViewController: self)
switch status {
case .completed:
    //User completed Persona
case .cancelled:
    //Persona was cancelled by the user
}
```

> Note: The result of ``VerificationSession/startIdentification(fromViewController:)`` does not indicate whether the verification is successful or not. It merely signals that the user completed the Persona identity process (or not). 

To wait for the identity verification to complete, use ``VerificationSession/resumeWhenIdentified()``, which suspends the Task and resumes when the user becomes verified.

### Logical flow for the verification

```swift
if verificationSession.verificationStatus == .processing {
    
    try await verificationSession.resumeWhenIdentified()
    
} else if verificationSession.verificationStatus == .notVerified {
    
    let identityFlow = try await verificationSession.startIdentification(fromViewController: self)
    
    if identityFlow == .completed {
        try await verificationSession.resumeWhenIdentified()
    }
}
```

## Select NFT image to mint

First you should obtain the possible NFT images by calling ``VerificationSession/getNFTImages()``. This returns an array of ``TokenImage``s, which has an ``TokenImage/url`` field usable to preview the NFT images. 

It is recommended to use `WKWebView` to display these images. They are SVGs, but they could be GIFs, PNGs, JPGs or other formats in the future.

After the user selected their image of choice, the minting has to be authorized for that particular image with ``VerificationSession/requestMinting(selectedImageId:)``

```swift
let nftImages = verificationSession.getNFTImages()
guard let selectedImage = nftImages.first else { return }
try await verificationSession.requestMinting(selectedImageId: selectedImage.id)
```

## Mint NFT

### Display gas fee estimation to user

```swift
let gasEstimation = try await verificationSession.estimateGasForMinting()
//Here mintinFee is an UILabel
mintingFee.text = gasEstimation.feeInNative
```
### Mint

The returned txURL can be used to let the user view their transaction on the explorer linked by the URL.

```swift
let txURL = try await verificationSession.mint()
```

## Flow summary

```swift

try await verificationSession.login()

if !verificationSession.disclaimerAccepted {
    try await verificationSession.acceptDisclaimer()
}

if !verificationSession.requiredInformationProvided {
    //Residency is in ISO 3166-2
    let personalData = PersonalData(email: "example@email.com",
                                    residency: "US",
                                    isLegalEntity: false)
    try await verificationSession.setPersonalData(personalData)
}

if !verificationSession.emailConfirmed {
    try await verificationSession.resumeOnEmailConfirmed()
}

if verificationSession.verificationStatus == .processing {
    
    try await verificationSession.resumeWhenIdentified()
    
} else if verificationSession.verificationStatus == .notVerified {
    
    let identityFlow = try await verificationSession.startIdentification(fromViewController: self)
    
    if identityFlow == .completed {
        try await verificationSession.resumeWhenIdentified()
    } else {
        //Handle cancellation, provide the user the ability to relaunch the identity verification
    }
}

let nftImages = verificationSession.getNFTImages()
guard let selectedImage = nftImages.first else { return }
try await verificationSession.requestMinting(selectedImageId: selectedImage.id)

let txURL = try await verificationSession.mint()

```
