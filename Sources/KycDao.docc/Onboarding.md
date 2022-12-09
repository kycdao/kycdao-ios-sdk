# Onboarding

A guide for the verification process and kycNFT minting

## Overview

This guide will help you implementing the whole process of minting a kycNFT.
The process consists of the following steps:
1. Login to kycDAO with your wallet
2. Make the user accept the disclaimer
3. Gather some personal information from the user
4. Confirm the email address
5. Verification
6. Select membership duration
7. Select kycNFT image to mint
8. Mint kycNFT

The user can end up at almost any point of the verification process. It is important to manage that users may interrupt the process and return later to complete the flow. You can determine the next step of the user using various state properties of the ``VerificationSession``, for example ``VerificationSession/disclaimerAccepted``. Keep in mind that these values may change for an existing user. For example the disclaimer acceptance will be reseted if the contents of the disclaimer change and a new user consent is required.

### Requirements

Before you can implement the verification flow, you must follow either the <doc:DAppIntegration> guide for DApps or the <doc:WalletIntegration> guide.

## 1. Login

Once you obtained a `VerificationSession` as shown in <doc:DAppIntegration> and <doc:WalletIntegration> guide, you can login your wallet to that session.

```swift
try await verificationSession.login()
```

## 2. Accepting the disclaimer

The user has to accept the disclaimer before being able to interact with kycDAO services. You can get the disclaimer text from ``VerificationSession/disclaimerText``, the ToS link from ``VerificationSession/termsOfService`` and the Privacy Policy link from ``VerificationSession/privacyPolicy``.

> Important: When implementing the SDK, you are required to show the full disclaimer to the user, and make them able to visit the ToS and PP.

```swift
if !verificationSession.disclaimerAccepted {
    try await verificationSession.acceptDisclaimer()
}
```

## 3. Gathering personal information

Check whether this step was already completed by the user by reading the value of ``VerificationSession/requiredInformationProvided``.

If not, then the required informations have to be provided by the user and submited. This step will fail if the disclaimer is not yet accepted.

```swift
if !verificationSession.requiredInformationProvided {
    //Residency is in ISO 3166-2
    let personalData = PersonalData(email: "example@email.com",
                                    residency: "US")
    try await verificationSession.setPersonalData(personalData)
}
```

A user's email address can be changed with ``VerificationSession/updateEmail(_:)``, but ***only*** if the user never requested minting before.

> Note: Calling ``VerificationSession/setPersonalData(_:)`` will send a confirmation email to the provided email address automatically

## 4. Confirm email

After calling ``VerificationSession/setPersonalData(_:)``, in order to proceed forward the email has to be confirmed by the user.

If the user failed to recive or lost the email, then it may be resent by calling ``VerificationSession/resendConfirmationEmail()``.
You could also let them edit their email address with ``VerificationSession/updateEmail(_:)`` to correct an incorrect email address.

```swift
try await verificationSession.resendConfirmationEmail()
```

To wait for email confirmation, call ``VerificationSession/resumeOnEmailConfirmed()``. It suspends the Task and resumes when the email becomes confirmed.

```swift
if !verificationSession.emailConfirmed {
    try await verificationSession.resumeOnEmailConfirmed()
}
```

## 5. Verification

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

To wait for the identity verification to complete, use ``VerificationSession/resumeOnVerificationCompleted()``, which suspends the Task and resumes when the user becomes verified.

### Logical flow for the verification

```swift
if verificationSession.verificationStatus == .processing {
    
    try await verificationSession.resumeOnVerificationCompleted()
    
} else if verificationSession.verificationStatus == .notVerified {
    
    let identityFlow = try await verificationSession.startIdentification(fromViewController: self)
    
    if identityFlow == .completed {
        try await verificationSession.resumeOnVerificationCompleted()
    }
}
```

## 6. Select membership duration

In order to mint a kycNFT, you need to purchase a kycDAO membership. 

- Check the user's membership status with ``VerificationSession/hasMembership``.

If the user does not have a membership, they have to buy one. They can buy memberships that last from a one year minimum period till multiple years. 

The price of membership goes up linearly with the membership duration. It is currently set in cost per year. 

- Get the current cost by calling ``VerificationSession/getMembershipCostPerYear()``

Your user can receive a discount for a number of years, for example the first year can be free, regardless of how many years you purchase: if you purchase 1 year, your membership for that 1 year subscription will be free in this case. 

- Estimate the user's membership payment for any number of years by calling ``VerificationSession/estimatePayment(yearsPurchased:)``
- Get the number of discounted years granted to the user from ``PaymentEstimation/discountYears``

> Important: If the user already has a membership, they can't purchase new memberships to extend their subscription periods. You should skip this step for them and make them continue with kycNFT selection. They can still remint their kycNFTs but they don't have to repurchase memberships for it.

```swift
// Display yearly membership cost in dollars
let cost = try await verificationSession.getMembershipCostPerYear()
membershipCost.text = "$\(cost) / year"

// Calculating membership payment estimation for 3 years
// then displaying the payment amount and applied discounts
let paymentEstimation = try await verificationSession.estimatePayment(yearsPurchased: 3)

if paymentEstimation.paymentAmount > 0 {
    membershipPayment.text = paymentEstimation.paymentAmountText
} else {
    membershipPayment.text = "Free"
}

if paymentEstimation.discountYears > 0 {
    discountYears.text = "Discounted years applied: \(paymentEstimation.discountYears)"
} else {
    discountYears.text = "No discounts"
}
```

The selected membership duration will be used to request minting with ``VerificationSession/requestMinting(selectedImageId:membershipDuration:)``

## 7. Select kycNFT image to mint

First you should obtain the possible kycNFT images by calling ``VerificationSession/getNFTImages()``. This returns an array of ``TokenImage``s, which has an ``TokenImage/url`` field usable to preview the kycNFT images. 

It is recommended to use `WKWebView` to display these images. They are SVGs, but they could be GIFs, PNGs, JPGs or other formats in the future.

After the user selected their image of choice, the minting has to be authorized for that particular image and selected membership duration (in years) with ``VerificationSession/requestMinting(selectedImageId:membershipDuration:)``. 

In case the user already has membership, setting a membership duration will have no effect, but it is recommended to set it to 0 for them.

```swift
let nftImages = verificationSession.getNFTImages()
guard let selectedImage = nftImages.first else { return }
try await verificationSession.requestMinting(selectedImageId: selectedImage.id, membershipDuration: 3)
```

## 8. Mint kycNFT

### Display mint price estimation to user

Call ``VerificationSession/getMintingPrice()`` for mint price estimation, which includes: 
- membership payment amount for the selected duration
- gas fee
- currency information 
- full price of minting

```swift
let mintingPrice = try await verificationSession.getMintingPrice()
//Here fullPrice is an UILabel
fullPrice.text = mintingPrice.fullPriceText
```

### Mint

The returned ``MintingResult`` can be used to let the user view their transaction on the explorer linked by ``MintingResult/explorerURL``, show them the kycNFT using ``MintingResult/imageURL``, or write some custom logic around ``MintingResult/tokenId`` and ``MintingResult/transactionId``.

```swift
let mintingResult = try await verificationSession.mint()
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
                                    residency: "US")
    try await verificationSession.setPersonalData(personalData)
}

if !verificationSession.emailConfirmed {
    try await verificationSession.resumeOnEmailConfirmed()
}

if verificationSession.verificationStatus == .processing {
    
    try await verificationSession.resumeOnVerificationCompleted()
    
} else if verificationSession.verificationStatus == .notVerified {
    
    let identityFlow = try await verificationSession.startIdentification(fromViewController: self)
    
    if identityFlow == .completed {
        try await verificationSession.resumeOnVerificationCompleted()
    } else {
        //Handle cancellation, provide the user the ability to relaunch the identity verification
    }
}

// Let the user choose their membership duration and show them the payment amount for membership
let selectedDuration = ...
let costPerYearUSD = try await verificationSession.getMembershipCostPerYear()
let paymentEstimation = try await verificationSession.estimatePayment(yearsPurchased: selectedDuration)

let nftImages = verificationSession.getNFTImages()
guard let selectedImage = nftImages.first else { return }

try await verificationSession.requestMinting(selectedImageId: selectedImage.id, 
                                             membershipDuration: selectedDuration)

// Display full price of minting (gas fee + membership cost)
let mintingPrice = try await verificationSession.getMintingPrice()

// Mint and show the transaction, image etc using the result
let mintingResult = try await verificationSession.mint()

```
