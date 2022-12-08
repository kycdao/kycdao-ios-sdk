//
//  Models.swift
//  
//
//  Created by Vekety Robin on 2022. 06. 17..
//

import Foundation
import BigInt

public enum KycDaoError: LocalizedError {
    case walletConnect(WalletConnectError)
    case keyGeneration
    case persona(Error)
    case httpStatusCode(response: HTTPURLResponse, data: Data)
    case unsupportedNetwork
    case genericError
    case unauthorizedMinting
    
//    public var errorDescription: String? {
//        switch self {
//        case .genericError:
//            return "generic error"
//        default:
//            return nil
//        }
//    }
//
//    public var failureReason: String? {
//        switch self {
//        case .genericError:
//            return "generic error"
//        default:
//            return nil
//        }
//    }
//
//    public var recoverySuggestion: String? {
//        switch self {
//        case .genericError:
//            return "generic error"
//        default:
//            return nil
//        }
//    }
//
//    public var helpAnchor: String? {
//        switch self {
//        case .genericError:
//            return "generic error"
//        default:
//            return nil
//        }
//    }
}

public enum WalletConnectError: Error {
    case failedToConnect(wallet: Wallet?)
    case sessionFailed
    case signingError(String)
}

public enum IdentityFlowResult {
    case completed
    case cancelled
}

struct BackendSessionDataDTO: Decodable {
    let id: String
    let nonce: String
    var user: UserDTO?
    let discount_years: UInt32?
}

struct BackendSessionData: Equatable {
    let id: String
    let nonce: String
    var user: User?
    let discountYears: UInt32?
    
    init(dto: BackendSessionDataDTO) {
        self.id = dto.id
        self.nonce = dto.nonce
        if let dtoUser = dto.user {
            self.user = User(dto: dtoUser)
        }
        self.discountYears = dto.discount_years
    }
}


public enum TokenImageType: String, Decodable {
    case identicon = "Identicon"
    case allowList = "AllowList"
    case typeSpecific = "TypeSpecific"
}

struct TokenImageDTO: Decodable {
    let image_type: TokenImageType
    let url: String
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

struct UserDTO: Decodable {
    let id: Int
    let ext_id: String?
    let email: String?
    let email_confirmed: String?
    let residency: String?
    let blockchain_accounts: [BlockchainAccountDetails]?
    let disclaimer_accepted: String?
    let legal_entity: Bool?
    let verification_requests: [VerificationRequestData]?
    let available_images: [String: TokenImageDTO]
    let subscription_expiry: Date?
    
    enum CodingKeys: CodingKey {
        case id
        case ext_id
        case email
        case email_confirmed
        case residency
        case blockchain_accounts
        case disclaimer_accepted
        case legal_entity
        case verification_requests
        case available_images
        case subscription_expiry
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.ext_id = try container.decodeIfPresent(String.self, forKey: .ext_id)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.email_confirmed = try container.decodeIfPresent(String.self, forKey: .email_confirmed)
        self.residency = try container.decodeIfPresent(String.self, forKey: .residency)
        self.blockchain_accounts = try container.decodeIfPresent([BlockchainAccountDetails].self, forKey: .blockchain_accounts)
        self.disclaimer_accepted = try container.decodeIfPresent(String.self, forKey: .disclaimer_accepted)
        self.legal_entity = try container.decodeIfPresent(Bool.self, forKey: .legal_entity)
        self.verification_requests = try container.decodeIfPresent([VerificationRequestData].self, forKey: .verification_requests)
        self.available_images = try container.decode([String : TokenImageDTO].self, forKey: .available_images)
        
        let expiryString = try container.decodeIfPresent(String.self, forKey: .subscription_expiry)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        
        guard let expiryString else {
            self.subscription_expiry = nil
            return
        }
        
        let expiryDate = dateFormatter.date(from: expiryString)
        self.subscription_expiry = expiryDate
    }
}

struct User: Equatable {
    let id: Int
    let ext_id: String?
    let email: String?
    let email_confirmed: String?
    let residency: String?
    let blockchain_accounts: [BlockchainAccountDetails]?
    let disclaimer_accepted: String?
    let legal_entity: Bool?
    let verification_requests: [VerificationRequestData]?
    let availableImages: [TokenImage]
    let subscription_expiry: Date?
    
    init(dto: UserDTO) {
        self.id = dto.id
        self.ext_id = dto.ext_id
        self.email = dto.email
        self.email_confirmed = dto.email_confirmed
        self.residency = dto.residency
        self.blockchain_accounts = dto.blockchain_accounts
        self.disclaimer_accepted = dto.disclaimer_accepted
        self.legal_entity = dto.legal_entity
        self.verification_requests = dto.verification_requests
        self.availableImages = dto.available_images.map { key, value in
            TokenImage(id: key,
                       imageType: value.image_type,
                       url: value.url.asURL)
        }
        self.subscription_expiry = dto.subscription_expiry
    }
}

struct ChainAndAddressDTO: Encodable {
    let blockchain: String
    let address: String
}

struct SignatureInputDTO: Encodable {
    let signature: String
    let public_key: String?
}

struct SmartContractConfig: Codable, Equatable {
    let address: String
    let paymentDiscountPercent: Int
    let verificationType: VerificationType
    let network: String
}

struct ApiStatus: Codable {
    let persona: PersonaStatus?
    let smartContractsInfo: [SmartContractConfig]
    
    enum ApiStatusKeys: String, CodingKey{
        case persona = "persona"
        case smartContractsInfo = "smart_contracts_info"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ApiStatusKeys.self)
        self.persona = try container.decodeIfPresent(PersonaStatus.self, forKey: .persona)
        
        //Swift does not encode/decode raw representable enums correctly into/from dictionaries, manual encode/decode is needed
        //https://forums.swift.org/t/json-encoding-decoding-weird-encoding-of-dictionary-with-enum-values/12995/10
        let networkDict = try container.decode([String: [String : SmartContractConfigDTO]].self,
                                               forKey: .smartContractsInfo)
        
        let parsedSmartContractInfoDict = networkDict.reduce([:])
            { (partialNetworkResult: [String: [VerificationType: SmartContractConfigDTO]], networkEntry: (String, [String: SmartContractConfigDTO])) in
            
                var networkResult = partialNetworkResult
                let network = networkEntry.0
                    
                networkResult[network] = networkEntry.1.reduce([:])
                    { (partialVerificationTypeResult: [VerificationType: SmartContractConfigDTO], verificationTypeEntry: (String, SmartContractConfigDTO)) in
                    
                        var verificationTypeResult = partialVerificationTypeResult
                        if let verificationType = VerificationType(rawValue: verificationTypeEntry.0) {
                            verificationTypeResult[verificationType] = verificationTypeEntry.1
                        }
                        
                        return verificationTypeResult
                                                              
                    }
                
                return networkResult
            
        }
        
        //Convert nested dictionary to actual object
        self.smartContractsInfo = parsedSmartContractInfoDict.flatMap { network, value in
            value.map { verificationType, dto in
                return SmartContractConfig(address: dto.address,
                                           paymentDiscountPercent: dto.payment_discount_percent,
                                           verificationType: verificationType,
                                           network: network)
            }
        }
    }
}

struct SmartContractConfigDTO: Codable {
    let address: String
    let payment_discount_percent: Int
}

struct PersonaStatus: Codable {
    let template_id: String?
    let sandbox: Bool?
}

struct UserUpdateInput: Codable {
    let email: String
    let residency: String
    let legal_entity: Bool
    
    init(email: String, residency: String, legalEntity: Bool) {
        self.email = email
        self.residency = residency
        self.legal_entity = legalEntity
    }
}

struct EmailConfirmInput: Codable {
    let confirm_code: String
}

struct BlockchainAccountDetails: Codable, Equatable {
    let id: Int
    let blockchain: Blockchain?
    let address: String?
    let tokens: [Token]
}

enum Blockchain: String, Codable {
    case ethereum = "Ethereum"
    case near = "Near"
}

struct Token: Codable, Equatable {
    let id: Int
    let network: String
    let authorization_code: String?
    let authorization_tx_id: String?
    let verification_type: VerificationType
    let minting_tx_id: String?
    let token_id: String?
}

//enum Chain: Codable {
//    case ethereumMainnet
//    case celoMainnet
//    case celoAlfajores
//    case polygonMumbai
//
//    var chainId: Int {
//        switch self {
//        case .ethereumMainnet:
//            <#code#>
//        case .celoMainnet:
//            <#code#>
//        case .celoAlfajores:
//            <#code#>
//        case .polygonMumbai:
//            <#code#>
//        }
//    }
//}

//public enum Network: String, Codable {
//    case ethereumMainnet = "EthereumMainnet"
//    case celoMainnet = "CeloMainnet"
//    case celoAlfajores = "CeloAlfajores"
//    case polygonMumbai = "PolygonMumbai"
//
//    public var chainId: Int {
//        switch self {
//        case .ethereumMainnet:
//            return 1
//        case .celoMainnet:
//            return 42220
//        case .celoAlfajores:
//            return 44787
//        case .polygonMumbai:
//            return 80001
//        }
//    }
//
//    public init?(chainId: Int) {
//        switch chainId {
//        case 80001:
//            self.init(rawValue: "PolygonMumbai")
//        case 1:
//            self.init(rawValue: "EthereumMainnet")
//        case 42220:
//            self.init(rawValue: "CeloMainnet")
//        case 44787:
//            self.init(rawValue: "CeloAlfajores")
//        default:
//            return nil
//        }
//    }
//
//    public init?(caip2Id: String) {
//        switch caip2Id {
//        case "eip155:1":
//            self.init(rawValue: "EthereumMainnet")
//        case "eip155:42220":
//            self.init(rawValue: "CeloMainnet")
//        case "eip155:44787":
//            self.init(rawValue: "CeloAlfajores")
//        case "eip155:80001":
//            self.init(rawValue: "PolygonMumbai")
//        default:
//            return nil
//        }
//    }
//
//    public var currency: NetworkCurrency {
//        switch self {
//        case .ethereumMainnet:
//            return .eth
//        case .celoMainnet:
//            return .celo
//        case .celoAlfajores:
//            return .celo
//        case .polygonMumbai:
//            return .matic
//        }
//    }
//
//    public var blockchain: Blockchain {
//        switch self {
//        case .ethereumMainnet,
//             .polygonMumbai,
//             .celoAlfajores,
//             .celoMainnet:
//            return .ethereum
//        }
//    }
//
//    public var caip2Id: String {
//        switch self {
//        case .ethereumMainnet:
//            return "eip155:1"
//        case .celoMainnet:
//            return "eip155:42220"
//        case .celoAlfajores:
//            return "eip155:44787"
//        case .polygonMumbai:
//            return "eip155:80001"
//        }
//    }
//}

public enum VerificationType: String, Codable, Hashable {
    case kyc = "KYC"
    case accreditedInvestor = "AccreditedInvestor"
}

struct MintRequestInput: Encodable {
    let blockchain_account_id: Int
    let network: String
    let selected_image_id: String
    let verification_type: VerificationType
    let subscription_duration: String
    
    init(accountId: Int, network: String, selectedImageId: String, subscriptionDuration: UInt32, verificationType: VerificationType = .kyc) {
        self.blockchain_account_id = accountId
        self.network = network
        self.selected_image_id = selectedImageId
        self.verification_type = verificationType
        //ISO 8601 formatted single year input 'PnY' where 'n' is the number of years
        self.subscription_duration = "P\(subscriptionDuration)Y"
    }
}

struct MintAuthorization: Decodable {
    let code: String?
    let tx_hash: String?
}

struct BackendErrorResponse: Decodable {
    let reference_id: String?
    let status_code: Int?
    let `internal`: Bool?
    let error_code: BackendErrorCode?
}

enum BackendErrorCode: String, Decodable {
    case disclaimerAlreadyAccepted = "DisclaimerAlreadyAccepted"
}

struct VerificationRequestData: Decodable, Equatable {
    
    let id: Int
    let user_id: Int
    let verification_type: VerificationType
    let status: VerificationStatusDTO
    
}

public enum VerificationStatus: Codable {
    case verified
    case processing
    case notVerified
}

enum VerificationStatusDTO: String, Decodable {
    case created = "Created"
    case failed = "Failed"
    case inReview = "InReview"
    case verified = "Verified"
    case notVerified = "NotVerified"
    
    var simplified: VerificationStatus {
        switch self {
        case .verified:
            return .verified
        case .inReview:
            return .processing
        case .notVerified, .failed, .created:
            return .notVerified
        }
    }
}

//enum NetworkCurrency: String {
//
//    case eth = "ETH"
//    case matic = "MATIC"
//    case celo = "CELO"
//
//    var weiToNativeDivisor: BigUInt {
//        BigUInt(integerLiteral: 1_000_000_000).power(2)
//    }
//
//    var minimumPrice: BigUInt {
//        BigUInt(50).gwei
//    }
//}

/// Contains gas fee estimation related data
public struct GasEstimation: Codable {
    
    /// The current gas price on the network
    public let price: BigUInt
    /// The gas amount required to run the transaction
    public let amount: BigUInt
    /// The currency used by the network
    public let gasCurrency: CurrencyData
    
    /// Gas fee estimation
    public var fee: BigUInt {
        price * amount
    }
    
    /// Gas fee estimation in an easy to display string representation including currency symbol
    public var feeText: String {
        fee.decimalText(divisor: gasCurrency.baseToNativeDivisor) + " \(gasCurrency.symbol)"
    }
    
    init(gasCurrency: CurrencyData, amount: BigUInt, price: BigUInt) {
        self.price = max(price, BigUInt(50).gwei)
        self.amount = amount
        self.gasCurrency = gasCurrency
    }
    
}

/// Contains membership payment estimation related data
public struct PaymentEstimation: Codable {
    
    /// The amount you have to pay for the service (membership cost)
    public let paymentAmount: BigUInt
    
    /// Number of discounted years you have available
    public let discountYears: UInt32
    
    /// The currency used by the network
    public let currency: CurrencyData
    
    /// `paymentAmount` in an easy to display string representation including currency symbol
    public var paymentAmountText: String {
        let baseToNativeDivisor = currency.baseToNativeDivisor
        let symbol = currency.symbol
        return paymentAmount.decimalText(divisor: baseToNativeDivisor) + " \(symbol)"
    }
}

/// Contains price estimation related data
public struct PriceEstimation: Codable {
    
    /// The amount you have to pay for the service (membership cost)
    public let paymentAmount: BigUInt
    
    /// Gas fee estimation
    public let gasFee: BigUInt?
    
    /// The currency used by the network
    public let currency: CurrencyData
    
    /// The full price of the transaction
    public var fullPrice: BigUInt {
        paymentAmount + (gasFee ?? 0)
    }
    
    /// `paymentAmount` in an easy to display string representation including currency symbol
    public var paymentAmountText: String {
        let baseToNativeDivisor = currency.baseToNativeDivisor
        let symbol = currency.symbol
        return paymentAmount.decimalText(divisor: baseToNativeDivisor) + " \(symbol)"
    }
    
    /// Gas fee estimation in an easy to display string representation including currency symbol
    public var gasFeeText: String? {
        guard let gasFee else { return nil }
        let baseToNativeDivisor = currency.baseToNativeDivisor
        let symbol = currency.symbol
        return gasFee.decimalText(divisor: baseToNativeDivisor) + " \(symbol)"
    }
    
    /// The full price of the transaction in an easy to display string representation including currency symbol
    public var fullPriceText: String {
        let baseToNativeDivisor = currency.baseToNativeDivisor
        let symbol = currency.symbol
        return fullPrice.decimalText(divisor: baseToNativeDivisor) + " \(symbol)"
    }
    
    init(paymentAmount: BigUInt, gasFee: BigUInt, currency: CurrencyData) {
        self.paymentAmount = paymentAmount
        self.gasFee = gasFee
        self.currency = currency
    }
    
}

struct MintingTransactionResult {
    let txHash: String
}

/// Data that describes a transaction used for minting
///
/// All values are in hex
public struct MintingProperties: Codable {
    
    /// The address of the smart contract we want to call
    public let contractAddress: String
    /// The ABI data of the smart contract
    public let contractABI: String
    /// Amount of gas required for minting
    public let gasAmount: String
    /// Price of a gas unit
    public let gasPrice: String
    
    /// The payment amount required to mint
    ///
    /// For EVM chains, this is the `value` field of a transaction object
    public let paymentAmount: String?
    
}

struct MintResultInput: Codable {
    
    let authorization_code: String
    let token_id: String
    let minting_tx_id: String
    
    init(authCode: String, tokenId: String, txHash: String) {
        authorization_code = authCode
        token_id = tokenId
        minting_tx_id = txHash
    }
    
}

typealias MintingTransactionHandler = (MintingProperties) async throws -> (MintingTransactionResult)

struct NetworkMetadata: Codable {
    
    let id: String
    let blockchain: String
    let name: String
    let caip2id: String
    //Only for EVM
    let chainId: UInt?
    let nativeCurrency: CurrencyData
    let explorer: ExplorerData
    
    enum CodingKeys: String, CodingKey {
        case id
        case blockchain
        case name
        case caip2id
        case chainId = "chain_id"
        case nativeCurrency = "native_currency"
        case explorer
    }
    
}

/// Currency information
public struct CurrencyData: Codable {
    /// Name of the currency
    public let name: String
    /// Symbol of the currency
    public let symbol: String
    /// Number of decimals required to represent 1 unit of the native currency with the base unit.
    ///
    /// For example 1 ETH is 10^18 Wei, in this case this field's value will be 18, ETH being the native currency and Wei being the base unit
    public let decimals: Int
    
    /// Divisor to convert from the base unit to the native currency.
    ///
    /// For example 1 ETH is 10^18 Wei, in this case this field's value will be 10^18
    public var baseToNativeDivisor: BigUInt {
        BigUInt(integerLiteral: 10).power(decimals)
    }
}

struct ExplorerData: Codable {
    let name: String
    let url: URL
    let transactionPath: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case url
        case transactionPath = "transaction_path"
    }
}

/// Personal data of the user
public struct PersonalData: Codable {
    
    /// Email address of the user
    public let email: String
    
    /// Country of residency of the user
    ///
    /// Contains the country of residency in [ISO 3166-2](https://en.wikipedia.org/wiki/ISO_3166-2) format.
    /// ##### Example
    /// ISO 3166-2 Code | Country name
    /// --- | ---
    /// `BE` | Belgium
    /// `ES` | Spain
    /// `FR` | France
    /// `US` | United States of America
    public let residency: String
    
    /// Legal entity status of the user
    public let isLegalEntity: Bool
    
    enum CodingKeys: String, CodingKey {
        case email
        case residency
        case isLegalEntity = "legal_entity"
    }
    
    ///
    /// - Parameters:
    ///   - email: Email address of the user
    ///   - residency: Country of residency of the user
    ///
    /// Country of residency is in [ISO 3166-2](https://en.wikipedia.org/wiki/ISO_3166-2) format.
    /// ##### Example
    /// ISO 3166-2 Code | Country name
    /// --- | ---
    /// `BE` | Belgium
    /// `ES` | Spain
    /// `FR` | France
    /// `US` | United States of America
    public init(email: String, residency: String) {
        self.email = email
        self.residency = residency
        self.isLegalEntity = false
    }
}

/// A set of configurations for any chain
///
/// You can create an `enum` that conforms to it or use ``KycDao/NetworkConfig`` instead
public protocol NetworkConfigProtocol: Hashable, Identifiable, Decodable {
    
    /// [CAIP-2](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md) chain id
    var chainId: String { get }
    
    /// RPC URL used for communicating with the chain.
    ///
    /// Leave it `nil` to use our default RPC URLs or provide your own RPC URL to use
    var rpcURL: URL? { get }
    
}

public extension NetworkConfigProtocol {
    
    /// ID of the network option, same as chainId
    var id: String {
        chainId
    }
}

/// A set of configurations for any chain
public struct NetworkConfig: NetworkConfigProtocol {
    
    /// ID of the network option, same as chainId
    public var id: String {
        chainId
    }
    
    /// [CAIP-2](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md) Chain ID
    public let chainId: String
    
    /// RPC URL used for communicating with the chain
    ///
    /// Leave it `nil` to use our default RPC URLs or provide your own RPC URL to use
    public let rpcURL: URL?
    
    /// Creates a configuration
    /// - Parameters:
    ///   - chainId: [CAIP-2](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md) chain id
    ///   - rpcURL: An RPC URL,  leave it `nil` to use our default RPC URLs or provide your own RPC URL to use
    public init(chainId: String, rpcURL: URL? = nil) {
        self.chainId = chainId
        self.rpcURL = rpcURL
    }
}

/*internal protocol AppliedNetworkConfigProtocol: Hashable, Identifiable {
    var chainId: String { get }
    var rpcURL: URL { get }
}

internal extension AppliedNetworkConfigProtocol {
    var id: String {
        chainId
    }
}*/

internal enum DefaultNetworkConfig: Hashable, Identifiable, CaseIterable {
    
    var id: String {
        chainId
    }
    
    case celoMainnet
    case celoAlfajores
    case polygonMainnet
    case polygonMumbai
    
    public var chainId: String {
        switch self {
        case .celoMainnet:
            return "eip155:42220"
        case .celoAlfajores:
            return "eip155:44787"
        case .polygonMainnet:
            return "eip155:89"
        case .polygonMumbai:
            return "eip155:80001"
        }
    }
    
    public var rpcURL: URL {
        switch self {
        case .celoMainnet:
            return URL(string: "https://forno.celo.org")!
        case .celoAlfajores:
            return URL(string: "https://alfajores-forno.celo-testnet.org")!
        case .polygonMainnet:
            return URL(string: "https://polygon-rpc.com")!
        case .polygonMumbai:
            return URL(string: "https://rpc-mumbai.maticvigil.com")!
        }
    }
    
    var asAppliedNetworkConfig: AppliedNetworkConfig {
        AppliedNetworkConfig(chainId: chainId,
                             rpcURL: rpcURL)
    }
}

/// A set of options for any chain
internal struct AppliedNetworkConfig: Hashable, Identifiable {
    
    var id: String {
        chainId
    }
    
    let chainId: String
    let rpcURL: URL
    
    init(chainId: String, rpcURL: URL) {
        self.chainId = chainId
        self.rpcURL = rpcURL
    }
}

/// The environments the SDK supports
public enum KycDaoEnvironment: Decodable {
    
    /// A production, live service environment
    case production
    /// A developer service environment
    case dev
    
    var serverURL: URL {
        switch self {
        case .production:
            return URL(string: "https://kycdao.xyz")!
        case .dev:
            return URL(string: "https://staging.kycdao.xyz")!
        }
    }
    
    var demoMode: Bool {
        switch self {
        case .production:
            return false
        case .dev:
            return true
        }
    }
}

/// A set of configuration options to initialize the kycDAO SDK
public struct Configuration {
    
    /// Selected environment to use
    public let environment: KycDaoEnvironment
    
    /// Network related configurations
    public let networkConfigs: [any NetworkConfigProtocol]
    
    /// Creates a configuration
    /// - Parameters:
    ///   - environment: Selected environment to use
    ///   - networkConfigs: Network related configurations
    public init(
//        apiKey: String,
        environment: KycDaoEnvironment,
        networkConfigs: [any NetworkConfigProtocol] = []
    ) {
//        self.apiKey = apiKey
        self.environment = environment
        self.networkConfigs = networkConfigs
    }
}

/// Describes the results of a successful mint
public struct MintingResult: Encodable {
    
    /// The transaction can be viewed in an explorer by opening the explorer URL
    public let explorerURL: URL?
    
    /// Id of the transaction
    public let transactionId: String
    
    /// Id of the minted token
    public let tokenId: String
    
    /// URL pointing to the minted image
    public let imageURL: URL?
}

internal struct PersonaSessionData {
    let referenceId: String
    let inquiryId: String
    let sessionToken: String
}

internal struct TokenDetailsDTO: Decodable {
    let image_url: String?
}

enum Constants {
    static let disclaimerText = """
Our Services allow individuals to obtain Know-Your-Customer (KYC)
reports from recognized providers like our Partners, the
verification proofs are represented in the unique kycDAO NFT
provided to and maintained for the identified blockchain wallet
address for each kycDAO User. kycDAO does not engage Third-Party
Collaborators to perform any services and is not a party to any
transaction or interaction between kycDAO Users and any Third-Party
Collaborator. kycDAO has not vetted, makes no representations
concerning, does not control, and has no liability for any of its
kycDAO Users interactions with Third Party Collaborators. kycDAO
does not control the services provided by Third Party Collaborators,
nor does kycDAO assume any responsibility for the accuracy or
reliability of any information provided by Third-Party
Collaborators. If you are a kycDAO User, any transactions that you
choose to engage in will be conducted through the blockchain network
governing the cryptocurrency address holding the kycDAO NFT. We are
not responsible for your blockchain address, wallet, their
interaction with Third-Party Collaborators and other blockchain
protocols, or the security of the private keys for your blockchain address.
"""
    
}
