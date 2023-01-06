//
//  VerificationSession.swift
//  
//
//  Created by Vekety Robin on 2022. 08. 11..
//

import Foundation
import WalletConnectSwift
import UIKit
import Persona2
import Combine
import web3
import BigInt

/// A verification session object which contains session related data and session related operations
public class VerificationSession: Identifiable {
    
    /// A unique identifier for the session
    public let id = UUID().uuidString
    /// Wallet address used to create the session
    public var walletAddress: String
    /// A wallet session associated with this VerificationSession
    public let walletSession: WalletSessionProtocol
    /// A disclaimer text to show to the users
    public let disclaimerText = Constants.disclaimerText
    /// Terms of service link to show
    public let termsOfService = URL(string: "https://kycdao.xyz/terms-and-conditions")!
    /// Privacy policy link to show
    public let privacyPolicy = URL(string: "https://kycdao.xyz/privacy-policy")!
    /// The ID of the chain used specified in [CAIP-2 format](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md)
    public var chainId: String { networkMetadata.caip2id }
    /// The login state of the user in this session
    public var loggedIn: Bool { user != nil }
    /// Email confirmation status of the user
    public var emailConfirmed: Bool { user?.emailConfirmed?.isEmpty == false }
    /// Disclaimer acceptance status of the user
    public var disclaimerAccepted: Bool { user?.disclaimerAccepted?.isEmpty == false }
    /// Indicates that the user provided every information required to continue with identity verification
    public var requiredInformationProvided: Bool {
        residencyProvided && emailProvided && user?.legalEntity != nil
    }
    /// Email address of the user
    public var emailAddress: String? { user?.email }
    
    /// The membership status of the user
    ///
    /// For users that are already members, you should skip the membership purchase step
    public var hasMembership: Bool {
        guard let expiry = sessionData.user?.subscriptionExpiry else { return false }
        return expiry.timeIntervalSinceReferenceDate > Date().timeIntervalSinceReferenceDate
    }
    
    private var identificationContinuation: CheckedContinuation<IdentityFlowResult, Error>?
    private var sessionData: BackendSessionData
    private let networkMetadata: NetworkMetadata
    private let networkConfig: AppliedNetworkConfig
    private let ethereumClient: EthereumHttpClient
    private var kycConfig: SmartContractConfig?
    private var accreditedConfig: SmartContractConfig?
    
    //Internal state
    private var authCode: String?
    private var personaSessionData: PersonaSessionData?
    
    //Derived internal
    private var loginProof: String { "kycDAO-login-\(sessionData.nonce)" }
    private var user: User? { sessionData.user }
    private var residency: String? { user?.residency }
    private var isLegalEntity: Bool? { user?.legalEntity }
    private var residencyProvided: Bool { residency?.isEmpty == false }
    private var emailProvided: Bool { emailAddress?.isEmpty == false }
    
    private var personaStatus: PersonaStatus {
        get async throws {
            let apiStatus = try await VerificationManager.shared.apiStatus()
            
            guard let personaStatus = apiStatus.persona
            else {
                throw KycDaoError.internal(.unknown)
            }
            
            return personaStatus
        }
    }
    
    /// Verification status of the user
    public var verificationStatus: VerificationStatus {
        
        let statuses = user?.verificationRequests?.map { verificationRequest -> VerificationStatus in
            if verificationRequest.verificationType != .kyc {
                return VerificationStatus.notVerified
            }
            return verificationRequest.status
        }
        
        guard let statuses = statuses else { return .notVerified }
        
        if statuses.contains(.verified) {
            return .verified
        } else if statuses.contains(.processing) {
            return .processing
        }
        
        return .notVerified
    }
    
    init(walletAddress: String,
         walletSession: WalletSessionProtocol,
         kycConfig: SmartContractConfig?,
         accreditedConfig: SmartContractConfig?,
         data: BackendSessionData,
         networkMetadata: NetworkMetadata,
         networkConfig: AppliedNetworkConfig) {
        self.walletAddress = walletAddress
        self.sessionData = data
        self.walletSession = walletSession
        self.kycConfig = kycConfig
        self.accreditedConfig = accreditedConfig
        self.networkMetadata = networkMetadata
        self.networkConfig = networkConfig
        self.ethereumClient = EthereumHttpClient(url: networkConfig.rpcURL)
    }
    
    /// Logs in the user to the current session
    ///
    /// The user will be redirected to their wallet where they have to sign a session data to login
    public func login() async throws {
        
        let signature = try await walletSession.personalSign(walletAddress: walletAddress, message: loginProof)
        
        let signatureInput = SignatureDTO(signature: signature,
                                          public_key: nil)
        
        do {
            
            let result = try await ApiConnection.call(endPoint: .user,
                                                      method: .POST,
                                                      input: signatureInput,
                                                      output: UserDTO.self)
            
            sessionData.user = User(dto: result.data)
            
        } catch KycDaoError.urlRequestError(let response, data: .backendError(let backendError)) {
            if backendError.errorCode == .userAlreadyLoggedIn {
                throw KycDaoError.userAlreadyLoggedIn
            }
            throw KycDaoError.urlRequestError(response: response, data: .backendError(backendError))
        } catch let error {
            throw error
        }
        
    }
    
    @discardableResult
    private func refreshUser() async throws -> User {
        
        let result = try await ApiConnection.call(endPoint: .user,
                                                  method: .GET,
                                                  output: UserDTO.self)
        let updatedUser = User(dto: result.data)
        sessionData.user = updatedUser
        return updatedUser
        
    }
    
    @discardableResult
    private func refreshSession() async throws -> BackendSessionData {
        
        let result = try await ApiConnection.call(endPoint: .session,
                                                  method: .GET,
                                                  output: BackendSessionDataDTO.self)
        let updatedSession = BackendSessionData(dto: result.data)
        sessionData = updatedSession
        return updatedSession
        
    }
    
    /// Used for signaling that the logged in user accepts kycDAO's disclaimer
    public func acceptDisclaimer() async throws {
        
        try precondition(loggedIn, throws: KycDaoError.userNotLoggedIn)
        
        do {
        
            try await ApiConnection.call(endPoint: .disclaimer, method: .POST)
        
            // Absorb .disclaimerAlreadyAccepted error and treat it as a non-error
        } catch KycDaoError.urlRequestError(let response, .backendError(let backendError)) {
            
            guard let errorCode = backendError.errorCode,
                  errorCode == .disclaimerAlreadyAccepted
            else {
                throw KycDaoError.urlRequestError(response: response, data: .backendError(backendError))
            }
            
        } catch let error {
            throw error
        }
        
        try await refreshUser()
        
    }
    
    /// Used for setting user related personal information.
    /// - Parameter personalData: Contains the personal data needed from the user
    ///
    /// - Important: Disclaimer has to be accepted before you can set the personal data
    ///
    /// - Important: After setting personal data a confirmation email will be sent out to the user automatically
    public func setPersonalData(_ personalData: PersonalData) async throws {
        
        try precondition(loggedIn, throws: KycDaoError.userNotLoggedIn)
        try precondition(disclaimerAccepted, throws: KycDaoError.disclaimerNotAccepted)
        
        let result = try await ApiConnection.call(endPoint: .user,
                                                  method: .PUT,
                                                  input: personalData,
                                                  output: UserDTO.self)
        
        sessionData.user = User(dto: result.data)
    }
    
    /// Updates the email address of the user
    /// - Parameter email: New email address
    ///
    /// - Important: Email confirmation is automatically sent, if the email is not confirmed yet.
    public func updateEmail(_ newEmail: String) async throws {
        
        //Throw user not logged in error
        try precondition(loggedIn, throws: KycDaoError.userNotLoggedIn)
        try precondition(disclaimerAccepted, throws: KycDaoError.disclaimerNotAccepted)
        try precondition(requiredInformationProvided, throws: KycDaoError.requiredInformationNotProvided)
        
        guard let residency
        else {
            throw KycDaoError.requiredInformationNotProvided
        }
        
        let personalData = PersonalData(email: newEmail,
                                        residency: residency)
        
        let result = try await ApiConnection.call(endPoint: .user,
                                                  method: .PUT,
                                                  input: personalData,
                                                  output: UserDTO.self)
        
        sessionData.user = User(dto: result.data)
    }
    
    /// Resends a confirmation email to the user's email address
    ///
    /// Initial confirmation email is sent out automatically after setting or updating email address
    ///
    /// - Important: If the email address is already confirmed or an email is not set for the user, then throws an error
    public func resendConfirmationEmail() async throws {
        try precondition(loggedIn, throws: KycDaoError.userNotLoggedIn)
        try precondition(disclaimerAccepted, throws: KycDaoError.disclaimerNotAccepted)
        try precondition(requiredInformationProvided, throws: KycDaoError.requiredInformationNotProvided)
        
        try await ApiConnection.call(endPoint: .emailConfirmation, method: .POST)
    }
    
    /// Suspends the current async task and continues execution when email address becomes confirmed.
    public func resumeOnEmailConfirmed() async throws {
        try precondition(loggedIn, throws: KycDaoError.userNotLoggedIn)
        try precondition(disclaimerAccepted, throws: KycDaoError.disclaimerNotAccepted)
        try precondition(requiredInformationProvided, throws: KycDaoError.requiredInformationNotProvided)
        
        var emailConfirmed = false
        
        while !emailConfirmed {
            // Delay the task by 3 second
            try? await Task.sleep(nanoseconds: 1_000_000_000 * 3)
            let user = try await refreshUser()
            emailConfirmed = user.emailConfirmed?.isEmpty == false
        }
        
    }
    
    
    /// Starts the identity verification process, uses [Persona](https://withpersona.com/)
    /// - Parameter viewController: The view controller on top of which you want to present the identity verification flow
    /// - Returns: The result of the identity verification flow.
    ///
    /// - Warning: The return value only tells whether the user completed the identity flow or cancelled it. Information regarding the validity of the identity verification can be accessed at ``KycDao/VerificationSession/verificationStatus``.
    /// - Important: The verification process may take a long time, you can actively wait for completion after the identity flow is done by by using ``VerificationSession/resumeOnVerificationCompleted()``
    @MainActor
    public func startIdentification(fromViewController viewController: UIViewController) async throws -> IdentityFlowResult {
        
        try precondition(loggedIn, throws: KycDaoError.userNotLoggedIn)
        try precondition(disclaimerAccepted, throws: KycDaoError.disclaimerNotAccepted)
        try precondition(requiredInformationProvided, throws: KycDaoError.requiredInformationNotProvided)
        
        guard let referenceId = sessionData.user?.extId else {
            throw KycDaoError.internal(.unknown)
        }
        
        guard requiredInformationProvided else { throw KycDaoError.internal(.unknown) }
        
        let personaStatus = try await personaStatus
        
        guard let templateId = personaStatus.template_id
        else {
            throw KycDaoError.internal(.unknown)
        }
        
        let environment = personaStatus.sandbox == false ? Environment.production : Environment.sandbox
        
        let config = InquiryConfiguration.build(inquiryId: personaSessionData?.inquiryId,
                                                sessionToken: personaSessionData?.sessionToken,
                                                environment: environment)
        
        if let personaSessionData,
           let config,
           personaSessionData.referenceId == referenceId {
            
            Inquiry(
                config: config,
                delegate: self
            ).start(from: viewController)
        } else {
            Inquiry(
                config: InquiryConfiguration(
                    templateId: templateId,
                    referenceId: referenceId,
                    environment: environment
                ),
                delegate: self
            ).start(from: viewController)
        }
        
        return try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<IdentityFlowResult, Error>) in
            self?.identificationContinuation = continuation
        }
        
    }
    
    /// A function which awaits until the user's identity becomes successfuly verified
    public func resumeOnVerificationCompleted() async throws {
        try precondition(loggedIn, throws: KycDaoError.userNotLoggedIn)
        try precondition(disclaimerAccepted, throws: KycDaoError.disclaimerNotAccepted)
        try precondition(requiredInformationProvided, throws: KycDaoError.requiredInformationNotProvided)
        
        var identified = false
        
        while !identified {
            
            // Delay the task by 3 second
            try? await Task.sleep(nanoseconds: 1_000_000_000 * 3)
            let user = try await refreshUser()
            
            if let verificationRequests = user.verificationRequests {
                identified = verificationRequests.contains {
                    $0.verificationType == .kyc && $0.status == .verified
                }
            }
        }
    }
    
    /// Provides the selectable kycNFT images
    /// - Returns: A list of image related data
    public func getNFTImages() async throws -> [TokenImage] {
        print(sessionData.user?.availableImages ?? [:])
        
        return sessionData.user?.availableImages
            .filter { $0.imageType == .identicon }
            .sorted(by: { $0.id > $1.id }) ?? []
        
    }
    
    public func regenerateNFTImages() async throws -> [TokenImage] {
        print(sessionData.user?.availableImages ?? [:])
        
//        let icons = try await ApiConnection.call(endPoint: .identicon, method: .GET, output: String.self)
//        print("icons ", icons)
        
        try await ApiConnection.call(endPoint: .identicon, method: .POST)
        try await refreshUser()
        
        return sessionData.user?.availableImages
            .filter { $0.imageType == .identicon }
            .sorted(by: { $0.id > $1.id }) ?? []
        
    }
    
    /// Use it for displaying annual membership cost to the user
    /// - Returns: The cost of membership per year in USD
    public func getMembershipCostPerYear() async throws -> String {
        
        guard let resolvedContractAddress = kycConfig?.address
        else {
            throw KycDaoError.internal(.missingContractAddress)
        }
        
        let contractAddress = EthereumAddress(resolvedContractAddress)
        let getSubscriptionCostFunction = KYCGetSubscriptionCostPerYearUSDFunction(contract: contractAddress)
        let subscriptionCostResult = try await getSubscriptionCostFunction.call(withClient: ethereumClient,
                                                                                responseType: KYCGetSubscriptionCostPerYearUSDResponse.self)
        
        let subscriptionCostBase = subscriptionCostResult.value
        
        let getSubscriptionCostDecimalsFunction = KYCGetSubscriptionCostDecimals(contract: contractAddress)
        
        let subscriptionCostDecimalsResult = try await getSubscriptionCostDecimalsFunction.call(withClient: ethereumClient,
                                                                                                responseType: KYCGetSubscriptionCostDecimalsResponse.self)
        
        let subscriptionCostDecimals = subscriptionCostDecimalsResult.value
        let subscriptionCostDivisor = BigUInt(integerLiteral: 10).power(subscriptionCostDecimals)
        
        let subscriptionCost = subscriptionCostBase.decimalText(divisor: subscriptionCostDivisor)
        
        return subscriptionCost
    }
    
    /// Requesting minting authorization for a selected image and membership duration
    /// - Parameter selectedImageId: The id of the image the user selected to mint
    /// - Parameter membershipDuration: Membership duration to purchase
    ///
    /// You can get the list of available images from ``KycDao/VerificationSession/getNFTImages()``
    public func requestMinting(selectedImageId: String, membershipDuration: UInt32) async throws {
        
        try precondition(loggedIn, throws: KycDaoError.userNotLoggedIn)
        try precondition(disclaimerAccepted, throws: KycDaoError.disclaimerNotAccepted)
        try precondition(requiredInformationProvided, throws: KycDaoError.requiredInformationNotProvided)
        try precondition(verificationStatus == .verified, throws: KycDaoError.identityNotVerified)
        
        guard let accountId = sessionData.user?.blockchainAccounts?.first?.id
        else { throw KycDaoError.internal(.missingBlockchainAccount) }
        
        let mintAuthInput = MintRequestDTO(accountId: accountId,
                                           network: networkMetadata.id,
                                           selectedImageId: selectedImageId,
                                           subscriptionDuration: membershipDuration)
        
        let result = try await ApiConnection.call(endPoint: .authorizeMinting,
                                                  method: .POST,
                                                  input: mintAuthInput,
                                                  output: MintAuthorizationDTO.self)
        let mintAuth = result.data
        
        guard let code = mintAuth.code, let txHash = mintAuth.tx_hash else {
            throw KycDaoError.internal(.unknown)
        }
        
        authCode = code
        
        try await resumeWhenTransactionFinished(txHash: txHash)
        
    }
    
    @discardableResult
    func resumeWhenTransactionFinished(txHash: String) async throws -> EthereumTransactionReceipt {
        
        let transactionStatus: EthereumTransactionReceiptStatus = .notProcessed
        
        while transactionStatus != .success {
            
            // Delay the task by 1 second
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            do {
                
                let receipt = try await getTransactionReceipt(txHash: txHash)
                print("receipt \(receipt)")
                return receipt
                
            } catch EthereumClientError.unexpectedReturnValue {
                continue
            } catch let error {
                throw error
            }
        }
        
        throw KycDaoError.internal(.unknown)
        
    }
    
    func getTransactionReceipt(txHash: String) async throws -> EthereumTransactionReceipt {
        return try await ethereumClient.eth_getTransactionReceipt(txHash: txHash)
    }
    
    func kycMintingFunction(authCode: String) throws -> KYCMintingFunction {
        
        guard let authCodeNumber = UInt32(authCode),
              let resolvedContractAddress = kycConfig?.address
        else {
            throw KycDaoError.internal(.unknown)
        }
        
        let contractAddress = EthereumAddress(resolvedContractAddress)
        let ethWalletAddress = EthereumAddress(walletAddress)
        
        return KYCMintingFunction(contract: contractAddress,
                                  authCode: authCodeNumber,
                                  from: ethWalletAddress,
                                  gasPrice: nil,
                                  gasLimit: nil)
    }
    
    private func getRawRequiredMintCostForCode(authCode: String) async throws -> BigUInt {
        
        guard let authCodeNumber = UInt32(authCode),
              let resolvedContractAddress = kycConfig?.address
        else {
            throw KycDaoError.internal(.unknown)
        }
        
        let contractAddress = EthereumAddress(resolvedContractAddress)
        let ethWalletAddress = EthereumAddress(walletAddress)
        let getRequiredMintingCostFunction = KYCGetRequiredMintCostForCodeFunction(contract: contractAddress,
                                                                                    authCode: authCodeNumber,
                                                                                    destination: ethWalletAddress)
        
        let result = try await getRequiredMintingCostFunction.call(withClient: ethereumClient,
                                                                   responseType: KYCGetRequiredMintCostForCodeResponse.self)
        
        return result.value
    }
    
    private func getRequiredMintCostForCode(authCode: String) async throws -> BigUInt {
        let mintingCost = try await getRawRequiredMintCostForCode(authCode: authCode)
        
        //Adding 10% slippage (no floating point operation for multiplying BigUInt with 1.1)
        let result = mintingCost.quotientAndRemainder(dividingBy: 10)
        let slippage = result.quotient
        
        return mintingCost + slippage
    }
    
    private func getRequiredMintCostForYears(_ years: UInt32) async throws -> BigUInt {
        
        guard let resolvedContractAddress = kycConfig?.address, years >= 1
        else {
            throw KycDaoError.internal(.unknown)
        }
        
        let discountYears = sessionData.discountYears ?? 0
        let yearsToPayFor = years - discountYears
        let yearsInSeconds = yearsToPayFor * 365 * 24 * 60 * 60
        
        let contractAddress = EthereumAddress(resolvedContractAddress)
        let getRequiredMintingCostFunction = KYCGetRequiredMintCostForSecondsFunction(contract: contractAddress,
                                                                                      seconds: yearsInSeconds)
        
        let result = try await getRequiredMintingCostFunction.call(withClient: ethereumClient,
                                                                   responseType: KYCGetRequiredMintCostForSecondsResponse.self)
        
        return result.value
    }
    
    
    /// Used for minting the kycNFT
    /// - Returns: Successful minting related data
    ///
    /// - Important: Can only be called after the user was authorized for minting with a selected image and membership duration with ``VerificationSession/requestMinting(selectedImageId:membershipDuration:)``
    @discardableResult
    public func mint() async throws -> MintingResult {
        
        try precondition(loggedIn, throws: KycDaoError.userNotLoggedIn)
        try precondition(disclaimerAccepted, throws: KycDaoError.disclaimerNotAccepted)
        try precondition(requiredInformationProvided, throws: KycDaoError.requiredInformationNotProvided)
        try precondition(verificationStatus == .verified, throws: KycDaoError.identityNotVerified)
        
        print("MINTING...")
        
        guard let authCode = authCode
        else { throw KycDaoError.unauthorizedMinting }
        
        let requiredMintCost = try await getRequiredMintCostForCode(authCode: authCode)
        let mintingFunction = try kycMintingFunction(authCode: authCode)
        let mintingTransaction = try mintingFunction.transaction(value: requiredMintCost)
        let props = try await transactionProperties(forTransaction: mintingTransaction)
        let txRes = try await walletSession.sendMintingTransaction(walletAddress: walletAddress, mintingProperties: props)
        let receipt = try await resumeWhenTransactionFinished(txHash: txRes.txHash)
        
        guard let event = receipt.lookForEvent(event: ERC721Events.Transfer.self)
        else { throw KycDaoError.internal(.unknown) }
        
        let tokenDetails = try await tokenMinted(authCode: authCode, tokenId: "\(event.tokenId)", txHash: txRes.txHash)
        
        self.authCode = nil
        
        guard let transactionURL = URL(string: networkMetadata.explorer.url.absoluteString + networkMetadata.explorer.transactionPath + txRes.txHash)
        else {
            return MintingResult(explorerURL: nil,
                                 transactionId: txRes.txHash,
                                 tokenId: "\(event.tokenId)",
                                 imageURL: tokenDetails.image_url?.asURL)
        }
        
        return MintingResult(explorerURL: transactionURL,
                             transactionId: txRes.txHash,
                             tokenId: "\(event.tokenId)",
                             imageURL: tokenDetails.image_url?.asURL)
        
    }
    
    func transactionProperties(forTransaction transaction: EthereumTransaction) async throws -> MintingProperties {
        
        let estimation = try await estimateGas(forTransaction: transaction)
        guard let transactionData = transaction.data?.web3.hexString
        else {
            throw KycDaoError.internal(.unknown)
        }
        
        return MintingProperties(contractAddress: transaction.to.value,
                                 contractABI: transactionData,
                                 gasAmount: estimation.amount.web3.hexString,
                                 gasPrice: estimation.price.web3.hexString,
                                 paymentAmount: transaction.value == 0 ? nil : transaction.value?.web3.hexString)
        
    }
    
    /// Use it for estimating minting price, including gas fees and payment for membership
    /// - Returns: The price estimation
    /// - Warning: Only call this function after you requested minting by calling ``KycDao/VerificationSession/requestMinting(selectedImageId:membershipDuration:)`` at some point, otherwise you will receive a ``KycDaoError/unauthorizedMinting`` error
    public func getMintingPrice() async throws -> PriceEstimation {
        
        try precondition(loggedIn, throws: KycDaoError.userNotLoggedIn)
        try precondition(disclaimerAccepted, throws: KycDaoError.disclaimerNotAccepted)
        try precondition(requiredInformationProvided, throws: KycDaoError.requiredInformationNotProvided)
        try precondition(verificationStatus == .verified, throws: KycDaoError.identityNotVerified)
        
        guard let authCode = authCode
        else { throw KycDaoError.unauthorizedMinting }
        
        let mintingFunction = try kycMintingFunction(authCode: authCode)
        let requiredMintCost = try await getRequiredMintCostForCode(authCode: authCode)
        let mintingTransaction = try mintingFunction.transaction(value: requiredMintCost)
        let gasEstimation = try await estimateGas(forTransaction: mintingTransaction)
        
        return PriceEstimation(paymentAmount: requiredMintCost,
                               gasFee: gasEstimation.fee,
                               currency: networkMetadata.nativeCurrency)
    }
    
    /// Use it for estimating membership costs for number of years
    /// - Parameter yearsPurchased: Number of years to purchase a membership for
    /// - Returns: The payment estimation
    public func estimatePayment(yearsPurchased: UInt32) async throws -> PaymentEstimation {
        
        try precondition(loggedIn, throws: KycDaoError.userNotLoggedIn)
        try precondition(disclaimerAccepted, throws: KycDaoError.disclaimerNotAccepted)
        try precondition(requiredInformationProvided, throws: KycDaoError.requiredInformationNotProvided)
        try precondition(verificationStatus == .verified, throws: KycDaoError.identityNotVerified)
        
        try await refreshSession()
        let membershipPayment = try await getRequiredMintCostForYears(yearsPurchased)
        let discountYears = sessionData.discountYears ?? 0
        
        return PaymentEstimation(paymentAmount: membershipPayment,
                                 discountYears: discountYears,
                                 currency: networkMetadata.nativeCurrency)
    }
    
    func estimateGas(forTransaction transaction: EthereumTransaction) async throws -> GasEstimation {
            
        //price in wei
        let ethGasPrice = try await ethereumClient.eth_gasPrice()
        let minGasPrice = BigUInt(50).gwei
        let price = max(ethGasPrice, minGasPrice)
        
        print("ethGasPrice \(ethGasPrice)")
        print("minGasPrice \(minGasPrice)")
        print("price \(price)")
        
        let amount = try await ethereumClient.eth_estimateGas(transaction)
        
        print("amount: \(amount)")
        
        let estimation = GasEstimation(gasCurrency: networkMetadata.nativeCurrency,
                                       amount: amount,
                                       price: ethGasPrice)
        
        print("fee: \(estimation.fee)")
        
        return estimation
    }
    
    func tokenMinted(authCode: String, tokenId: String, txHash: String) async throws -> TokenDetailsDTO {
        
        let mintResultInput = MintResultUploadDTO(authCode: authCode,
                                                  tokenId: tokenId,
                                                  txHash: txHash)
        
        let result = try await ApiConnection.call(endPoint: .token,
                                                  method: .POST,
                                                  input: mintResultInput,
                                                  output: TokenDetailsDTO.self)
        
        return result.data
        
    }
    
}

extension VerificationSession: InquiryDelegate {
    
    public func inquiryComplete(inquiryId: String, status: String, fields: [String : InquiryField]) {
        print("Persona completed")
        personaSessionData = nil
        identificationContinuation?.resume(returning: .completed)
        identificationContinuation = nil
    }
    
    public func inquiryCanceled(inquiryId: String?, sessionToken: String?) {
        print("Persona canceled")
        
        if let inquiryId, let sessionToken, let referenceId = sessionData.user?.extId {
            personaSessionData = PersonaSessionData(referenceId: referenceId, inquiryId: inquiryId, sessionToken: sessionToken)
        }
        
        identificationContinuation?.resume(returning: .cancelled)
        identificationContinuation = nil
    }
    
    public func inquiryError(_ error: Error) {
        print("Inquiry error")
        personaSessionData = nil
        identificationContinuation?.resume(throwing: KycDaoError.persona(error))
        identificationContinuation = nil
    }
    
}
