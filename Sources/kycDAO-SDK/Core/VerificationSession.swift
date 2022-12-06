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
    
    private var identificationContinuation: CheckedContinuation<IdentityFlowResult, Error>?
    
    private var sessionData: BackendSessionData
    
    /// Wallet address used to create the session
    public var walletAddress: String
    
    private var kycConfig: SmartContractConfig?
    private var accreditedConfig: SmartContractConfig?
    
    private var loginProof: String {
        "kycDAO-login-\(sessionData.nonce)"
    }
    
    private var user: User? {
        sessionData.user
    }
    
    /// The login state of the user in this session
    public var loggedIn: Bool {
        user != nil
    }
    
    /// Email address associated with the user
    private var emailAddress: String? {
        user?.email
    }
    
    private var personaStatus: PersonaStatus {
        get async throws {
            let apiStatus = try await VerificationManager.shared.apiStatus()
            
            guard let personaStatus = apiStatus.persona
            else {
                throw KycDaoError.genericError
            }
            
            return personaStatus
        }
    }
    
    /// Email confirmation status of the user
    public var emailConfirmed: Bool {
        user?.email_confirmed?.isEmpty == false
    }
    
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
    private var residency: String? {
        user?.residency
    }
    
    private var isLegalEntity: Bool? {
        user?.legal_entity
    }
    
    private var residencyProvided: Bool {
        residency?.isEmpty == false
    }
    
    private var emailProvided: Bool {
        emailAddress?.isEmpty == false
    }
    
    /// Disclaimer acceptance status of the user
    public var disclaimerAccepted: Bool {
        user?.disclaimer_accepted?.isEmpty == false
    }
    
    /// Indicates that the user provided every information required to continue with identity verification
    public var requiredInformationProvided: Bool {
        residencyProvided && emailProvided && user?.legal_entity != nil
    }
    
    private var authCode: String?
    private var personaSessionData: PersonaSessionData?
    
    /// Verification status of the user
    public var verificationStatus: VerificationStatus {
        
        let statuses = user?.verification_requests?.map { verificationRequest -> VerificationStatus in
            if verificationRequest.verification_type != .kyc {
                return VerificationStatus.notVerified
            }
            return verificationRequest.status.simplified
        }
        
        guard let statuses = statuses else { return .notVerified }
        
        if statuses.contains(.verified) {
            return .verified
        } else if statuses.contains(.processing) {
            return .processing
        }
        
        return .notVerified
    }
    
    /// The membership status of the user
    ///
    /// For users that are already members, you should skip the membership purchase step
    public var hasMembership: Bool {
        guard let expiry = sessionData.user?.subscription_expiry else { return false }
        return expiry.timeIntervalSinceReferenceDate > Date().timeIntervalSinceReferenceDate
    }
    
    /// A disclaimer text to show to the users
    public let disclaimerText = Constants.disclaimerText
    /// Terms of service link to show
    public let termsOfService = URL(string: "https://kycdao.xyz/terms-and-conditions")!
    /// Privacy policy link to show
    public let privacyPolicy = URL(string: "https://kycdao.xyz/privacy-policy")!
    
    /// A wallet session associated with this VerificationSession
    public let walletSession: WalletSessionProtocol
    private let networkMetadata: NetworkMetadata
    private let networkConfig: AppliedNetworkConfig
    
    /// The ID of the chain used specified in [CAIP-2 format](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md)
    public var chainId: String {
        networkMetadata.caip2id
    }
    
    private let ethereumClient: EthereumHttpClient
    
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
        
        let appState = await UIApplication.shared.applicationState
        var state = appState == .active ? "active" : (appState == .background ? "background" : "inactive")
        print("appState \(state) mainThread: \(Thread.isMainThread)")
        
        let signatureInput = SignatureInputDTO(signature: signature,
                                               public_key: nil)
        
        let result = try await ApiConnection.call(endPoint: .user,
                                                  method: .POST,
                                                  input: signatureInput,
                                                  output: UserDTO.self)
        
        sessionData.user = User(dto: result.data)
        
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
    
    /// Used for signaling that the logged in user accepts kycDAO's disclaimer
    public func acceptDisclaimer() async throws {
        
        do {
        
            let _ = try await ApiConnection.call(endPoint: .disclaimer, method: .POST)
        
        } catch KycDaoError.httpStatusCode(_, let data) {
        
            let serverError = try JSONDecoder().decode(BackendErrorResponse.self, from: data)
            
            guard let errorCode = serverError.error_code else {
                throw KycDaoError.genericError
            }
            
            switch errorCode {
            case .disclaimerAlreadyAccepted:
                return
            }
            
            throw KycDaoError.genericError
            
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
        
        //TODO: Fail if disclaimer not set, send confirm email
        
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
        guard user != nil else { throw KycDaoError.genericError }
        
        //Proper error: email can only be updated after personal data have been set up
        guard requiredInformationProvided,
              let residency,
              let isLegalEntity
        else {
            throw KycDaoError.genericError
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
    /// - Important: If the email address is already confirmed or an email address is not set for the user, then throws an error
    public func resendConfirmationEmail() async throws {
        try await ApiConnection.call(endPoint: .emailConfirmation, method: .POST)
    }
    
    /// Suspends the current async task and continues execution when email address becomes confirmed.
    public func resumeOnEmailConfirmed() async throws {
        
        var emailConfirmed = false
        
        while !emailConfirmed {
            // Delay the task by 3 second
            try? await Task.sleep(nanoseconds: 1_000_000_000 * 3)
            let user = try await refreshUser()
            emailConfirmed = user.email_confirmed?.isEmpty == false
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
        
        //TODO: block if data needed
        
        guard let referenceId = sessionData.user?.ext_id else {
            throw KycDaoError.genericError
        }
        
        guard requiredInformationProvided else { throw KycDaoError.genericError }
        
        let personaStatus = try await personaStatus
        
        guard let templateId = personaStatus.template_id
        else {
            throw KycDaoError.genericError
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
        
        var identified = false
        
        while !identified {
            
            // Delay the task by 3 second
            try? await Task.sleep(nanoseconds: 1_000_000_000 * 3)
            let user = try await refreshUser()
            
            if let verificationRequests = user.verification_requests {
                identified = verificationRequests.contains {
                    $0.verification_type == .kyc && $0.status == .verified
                }
            }
        }
    }
    
    /// Provides the selectable NFT images
    /// - Returns: A list of image related data
    public func getNFTImages() -> [TokenImage] {
        print(sessionData.user?.availableImages ?? [:])
        
        return sessionData.user?.availableImages
            .filter { $0.imageType == .identicon } ?? []
        
    }
    
    /// Use it for displaying annual membership cost to the user
    /// - Returns: The cost of membership per year
    public func getMembershipCostPerYear() async throws -> BigUInt {
        
        guard let resolvedContractAddress = kycConfig?.address
        else {
            throw KycDaoError.genericError
        }
        
        let contractAddress = EthereumAddress(resolvedContractAddress)
        let getSubscriptionCostFunction = KYCGetSubscriptionCostPerYearUSDFunction(contract: contractAddress)
        let result = try await getSubscriptionCostFunction.call(withClient: ethereumClient, responseType: KYCGetSubscriptionCostPerYearUSDResponse.self)
        
        return result.value
    }
    
    /// Requesting minting authorization for a selected image and membership duration
    /// - Parameter selectedImageId: The id of the image the user selected to mint
    /// - Parameter membershipDuration: Membership duration to purchase
    ///
    /// You can get the list of available images from ``KycDao/VerificationSession/getNFTImages()``
    public func requestMinting(selectedImageId: String, membershipDuration: UInt32) async throws {
        
        guard let accountId = sessionData.user?.blockchain_accounts?.first?.id
        else { throw KycDaoError.genericError }
        
        let mintAuthInput = MintRequestInput(accountId: accountId,
                                             network: networkMetadata.id,
                                             selectedImageId: selectedImageId,
                                             subscriptionDuration: membershipDuration)
        
        let result = try await ApiConnection.call(endPoint: .authorizeMinting,
                                                  method: .POST,
                                                  input: mintAuthInput,
                                                  output: MintAuthorization.self)
        let mintAuth = result.data
        
        guard let code = mintAuth.code, let txHash = mintAuth.tx_hash else {
            throw KycDaoError.genericError
        }
        
        authCode = code
        
        try await resumeWhenTransactionFinished(txHash: txHash)
        
    }
    
    @discardableResult
    func resumeWhenTransactionFinished(txHash: String) async throws -> EthereumTransactionReceipt {
        
        let transactionStatus: EthereumTransactionReceiptStatus = .notProcessed
        
        print("continue block")
        
        while transactionStatus != .success {
            
            print("while begin: \(transactionStatus)")
            
            // Delay the task by 1 second
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            print("sleep end")
            
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
        
        throw KycDaoError.genericError
        
    }
    
    func getTransactionReceipt(txHash: String) async throws -> EthereumTransactionReceipt {
        
        print("will init client")
        
        print("getting receipt")
        let receipt = try await ethereumClient.eth_getTransactionReceipt(txHash: txHash)
        print("got receipt")
        return receipt
        
    }
    
    func kycMintingFunction(authCode: String) throws -> KYCMintingFunction {
        
        guard let authCodeNumber = UInt32(authCode),
              let resolvedContractAddress = kycConfig?.address
        else {
            throw KycDaoError.genericError
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
            throw KycDaoError.genericError
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
        do {
            let mintingCost = try await getRawRequiredMintCostForCode(authCode: authCode)
            
            //Adding 10% slippage (no floating point operation for multiplying BigUInt with 1.1)
            let result = mintingCost.quotientAndRemainder(dividingBy: 10)
            let slippage = result.quotient
            
            return mintingCost + slippage
        } catch {
            print("FAILED CODE")
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return try await getRequiredMintCostForCode(authCode: authCode)
        }
    }
    
    private func getRequiredMintCostForYears(_ years: UInt32) async throws -> BigUInt {
        
        //Would be nice: throw different error for less than 1 year
        guard let resolvedContractAddress = kycConfig?.address, years >= 1
        else {
            throw KycDaoError.genericError
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
    
    
    /// Used for minting the NFT image
    /// - Returns: Successful minting related data
    ///
    /// - Important: Can only be called after the user was authorized for minting with a selected image and membership duration with ``VerificationSession/requestMinting(selectedImageId:membershipDuration:)``
    @discardableResult
    public func mint() async throws -> MintingResult? {
        
        print("MINTING...")
        
        guard let authCode = authCode
        else { throw KycDaoError.unauthorizedMinting }
        
        let requiredMintCost = try await getRequiredMintCostForCode(authCode: authCode)
        let mintingFunction = try kycMintingFunction(authCode: authCode)
        let mintingTransaction = try mintingFunction.transaction(value: requiredMintCost)
        let props = try await transactionProperties(forTransaction: mintingTransaction)
        let txHash = try await walletSession.sendMintingTransaction(walletAddress: walletAddress, mintingProperties: props)
        let receipt = try await resumeWhenTransactionFinished(txHash: txHash)
        
        guard let event = receipt.lookForEvent(event: ERC721Events.Transfer.self)
        else { throw KycDaoError.genericError }
        
        let tokenDetails = try await tokenMinted(authCode: authCode, tokenId: "\(event.tokenId)", txHash: txHash)
        
        self.authCode = nil
        
        guard let transactionURL = URL(string: networkMetadata.explorer.url.absoluteString + networkMetadata.explorer.transactionPath + txHash)
        else {
            return MintingResult(explorerURL: nil,
                                 transactionId: txHash,
                                 tokenId: "\(event.tokenId)",
                                 imageURL: tokenDetails.image_url?.asURL)
        }
        
        return MintingResult(explorerURL: transactionURL,
                             transactionId: txHash,
                             tokenId: "\(event.tokenId)",
                             imageURL: tokenDetails.image_url?.asURL)
        
    }
    
    func transactionProperties(forTransaction transaction: EthereumTransaction) async throws -> MintingProperties {
        
        let estimation = try await estimateGas(forTransaction: transaction)
        guard let transactionData = transaction.data?.web3.hexString
        else {
            throw KycDaoError.genericError
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
        let membershipPayment = try await getRequiredMintCostForYears(yearsPurchased)
        let discountYears = sessionData.discountYears ?? 0
        
        return PaymentEstimation(paymentAmount: membershipPayment,
                                 discountYears: discountYears,
                                 currency: networkMetadata.nativeCurrency)
    }
    
    func estimateGas(forTransaction transaction: EthereumTransaction) async throws -> GasEstimation {
        
        do {
            
            print("will init client")
            
            print("getting price")
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
            
        } catch {
            print("FAILED GAS")
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return try await estimateGas(forTransaction: transaction)
        }
        
    }
    
    func tokenMinted(authCode: String, tokenId: String, txHash: String) async throws -> TokenDetailsDTO {
        
        let mintResultInput = MintResultInput(authCode: authCode,
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
        
        if let inquiryId, let sessionToken, let referenceId = sessionData.user?.ext_id {
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
