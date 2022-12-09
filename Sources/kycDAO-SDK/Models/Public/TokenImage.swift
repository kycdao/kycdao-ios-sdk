//
//  TokenImage.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation

public enum TokenImageType: String, Decodable {
    case identicon = "Identicon"
    case allowList = "AllowList"
    case typeSpecific = "TypeSpecific"
}

/// Image related data
///
/// Can be used for
/// - displaying the image via the URL on your UI
/// - selecting an image and authorizing minting for it
///     - ``KycDao/VerificationSession/requestMinting(selectedImageId:membershipDuration:)``
public struct TokenImage: Equatable {
    /// The id of this image
    public let id: String
    /// The type of the image
    public let imageType: TokenImageType
    /// URL pointing to the image
    public let url: URL?
}
