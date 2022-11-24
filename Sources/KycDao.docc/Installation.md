# Installation

Adding kycDAO SDK to your project

## Swift Package Manager

Use Xcode to add to the project (**File** -> **Swift Packages**) and add 

```http 
https://github.com/kycdao/kycdao-ios-sdk
```

or 

add this to your `Package.swift` file:

```swift
.package(url: "https://github.com/kycdao/kycdao-ios-sdk", from: "1.0.0")
```

## CocoaPods

Add KycDao to your Podfile:

```perl
pod 'KycDao'
```

Then run the following command:

```shell
$ pod install
```

## Importing to source file

Add an import at the top of your source file

```swift
import KycDao
```

That's it. You can start coding.
