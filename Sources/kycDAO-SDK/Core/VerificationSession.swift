//
//  KYCSession.swift
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
    private let personaInquiryTemplateId = "itmpl_bWGWAeN5fDcv5PLqLwFhKxP6"
    private let infuraProjectId = "8edae24121f74398b57da7ff5a3729a4"
    
    private var identificationContinuation: CheckedContinuation<IdentityFlowResult, Error>?
    
    private var sessionData: BackendSessionData
    
    /// Wallet address used to create the session
    public var walletAddress: String
    
    private var kycConfig: SmartContractConfig?
    private var accreditedConfig: SmartContractConfig?
    
    private var loginProof: String {
        "kycDAO-login-\(sessionData.nonce)"
    }
    
    /// The login state of the user in this session
    public var loggedIn: Bool {
        sessionData.user != nil
    }
    
    /// Email address associated with the user
    private var emailAddress: String? {
        sessionData.user?.email
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
        
//        //TODO: Nice to have, proper date format check, not just emptyness
//        get async throws {
//
//            let user = try await getUser()
//            print(user.email_confirmed)
//            return user.email_confirmed?.isEmpty == false
//
//        }
        
        sessionData.user?.email_confirmed?.isEmpty == false
        
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
        sessionData.user?.residency
    }
    
    
    private var residencyProvided: Bool {
        residency?.isEmpty == false
    }
    
    private var emailProvided: Bool {
        emailAddress?.isEmpty == false
    }
    
    /// Disclaimer acceptance status of the user
    public var disclaimerAccepted: Bool {
        sessionData.user?.disclaimer_accepted?.isEmpty == false
    }
    
    /// Indicates that the user provided every information required to continue with identity verification
    public var requiredInformationProvided: Bool {
        residencyProvided && emailProvided && sessionData.user?.legal_entity != nil
    }
    
    private var authCode: String?
    
    /// Verification status of the user
    public var verificationStatus: VerificationStatus {
        
        let statuses = sessionData.user?.verification_requests?.map { verificationRequest -> VerificationStatus in
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
    
    /// A wallet session associated with this VerificationSession
    public let walletSession: WalletSessionProtocol
    private let networkMetadata: NetworkMetadata
    
    /// The ID of the chain used specified in [CAIP-2 format](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md)
    public var chainId: String {
        networkMetadata.caip2id
    }
    
    init(walletAddress: String,
         walletSession: WalletSessionProtocol,
         kycConfig: SmartContractConfig?,
         accreditedConfig: SmartContractConfig?,
         data: BackendSessionData,
         networkMetadata: NetworkMetadata) {
        self.walletAddress = walletAddress
        self.sessionData = data
        self.walletSession = walletSession
        self.kycConfig = kycConfig
        self.accreditedConfig = accreditedConfig
        self.networkMetadata = networkMetadata
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
    ///  Disclaimer has to be accepted before you can set the personal data
    ///
    ///  After setting personal data a confirmation email will be sent out to the user
    public func setPersonalData(_ personalData: PersonalData) async throws {
        
        //TODO: Fail if disclaimer not set, send confirm email
        
        let result = try await ApiConnection.call(endPoint: .user,
                                                  method: .PUT,
                                                  input: personalData,
                                                  output: UserDTO.self)
        
        sessionData.user = User(dto: result.data)
        
        try await sendConfirmationEmail()
        
    }
    
    /// Sends a confirmation email to the user's email address
    public func sendConfirmationEmail() async throws {
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
    /// - Returns: The result of the identity verification flow. It only tells wether the user completed the identity flow or cancelled it. Information regarding the validity of the identity verification can be accessed at ``KycDao/VerificationSession/verificationStatus``
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
        
        Inquiry(
            config: InquiryConfiguration(
//                templateId: personaInquiryTemplateId,
                templateId: templateId,
                referenceId: referenceId,
                environment: environment
            ),
            delegate: self
        ).start(from: viewController)
        
        return try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<IdentityFlowResult, Error>) in
            self?.identificationContinuation = continuation
        }
        
    }
    
    /// A function which awaits until the user's identity becomes successfuly verified
    public func resumeWhenIdentified() async throws {
        
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
    
    /// Requesting minting authorization for a selected image
    /// - Parameter selectedImageId: The id of the image we want the user to mint
    ///
    /// You can get the list of available images from ``KycDao/VerificationSession/getNFTImages()``
    public func requestMinting(selectedImageId: String) async throws {
        
        guard let accountId = sessionData.user?.blockchain_accounts?.first?.id
        else { throw KycDaoError.genericError }
        
        let mintAuthInput = MintRequestInput(accountId: accountId,
                                             network: networkMetadata.id,
                                             selectedImageId: selectedImageId)
        
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
        
        var transactionStatus: EthereumTransactionReceiptStatus = .notProcessed
        
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
            
            print("while end")
        }
        
        throw KycDaoError.genericError
        
    }
    
    func getTransactionReceipt(txHash: String) async throws -> EthereumTransactionReceipt {
        
        let projectID = "8edae24121f74398b57da7ff5a3729a4"
        
        print("getTransactionReceipt")
        
        guard let clientUrl = URL(string: "https://polygon-mumbai.infura.io/v3/\(projectID)") else {
            throw KycDaoError.genericError
        }
        
        print("will init client")
        
        let client = EthereumClient(url: clientUrl)
        
        print("getting receipt")
        let receipt = try await client.eth_getTransactionReceipt(txHash: txHash)
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
    
    /// Used for minting the NFT image
    /// - Returns: An URL for an explorer where the minting transaction can be viewed
    ///
    /// - Note: Can only be called after the user was authorized for minting with a selected image
    @discardableResult
    public func mint() async throws -> URL? {
        
        print("MINTING...")
        
        guard let authCode = authCode
        else { throw KycDaoError.unauthorizedMinting }
        
        let mintingFunction = try kycMintingFunction(authCode: authCode)
        let props = try await transactionProperties(forFunction: mintingFunction)
        let txHash = try await walletSession.sendMintingTransaction(walletAddress: walletAddress, mintingProperties: props)
        let receipt = try await resumeWhenTransactionFinished(txHash: txHash)
        
        guard let event = receipt.lookForEvent(event: ERC721Events.Transfer.self)
        else { throw KycDaoError.genericError }
        
        try await tokenMinted(authCode: authCode, tokenId: "\(event.tokenId)", txHash: txHash)
        
        self.authCode = nil
        
        guard let transactionURL = URL(string: networkMetadata.explorer.url.absoluteString + networkMetadata.explorer.transactionPath + txHash)
        else {
            return nil
        }
        
        return transactionURL
        
    }
    
    func transactionProperties(forFunction function: ABIFunction) async throws -> MintingProperties {
        
        let estimation = try await estimateGas(forFunction: function)
        guard let transactionData = try function.transaction().data?.web3.hexString
        else {
            throw KycDaoError.genericError
        }
        
        return MintingProperties(contractAddress: function.contract.value,
                                 contractABI: transactionData,
                                 gasAmount: estimation.amount.web3.hexString,
                                 gasPrice: estimation.price.web3.hexString)
        
    }
    
    /// Used for estimating gas fees for the minting
    /// - Returns: The gas fee estimation
    public func estimateGasForMinting() async throws -> GasEstimation {
        
        guard let authCode = authCode
        else { throw KycDaoError.unauthorizedMinting }
        
        let mintingFunction = try kycMintingFunction(authCode: authCode)
        
        return try await estimateGas(forFunction: mintingFunction)
        
    }
    
    func estimateGas(forFunction function: ABIFunction) async throws -> GasEstimation {
        
        print("estimateGas")
        
        guard let clientUrl = URL(string: "https://polygon-mumbai.infura.io/v3/\(infuraProjectId)") else {
            throw KycDaoError.genericError
        }
        
        print("will init client")
        
        let client = EthereumClient(url: clientUrl)
        
        print("getting price")
        //price in wei
        let ethGasPrice = try await client.eth_gasPrice()
        let minGasPrice = BigUInt(50).gwei
        let price = max(ethGasPrice, minGasPrice)
        
        print("ethGasPrice \(ethGasPrice)")
        print("minGasPrice \(minGasPrice)")
        print("price \(price)")
        
        
        let amount = try await client.eth_estimateGas(function.transaction())
        
        print("amount: \(amount)")
        
        let estimation = GasEstimation(gasCurrency: networkMetadata.nativeCurrency,
                                       amount: amount,
                                       price: ethGasPrice)
        
        print("fee: \(estimation.fee)")
        
        return estimation
        
    }
    
    func tokenMinted(authCode: String, tokenId: String, txHash: String) async throws {
        
        let mintResultInput = MintResultInput(authCode: authCode,
                                              tokenId: tokenId,
                                              txHash: txHash)
        
        try await ApiConnection.call(endPoint: .token, method: .POST, input: mintResultInput)
        
    }
    
}

extension VerificationSession: InquiryDelegate {
    
    public func inquiryComplete(inquiryId: String, status: String, fields: [String : InquiryField]) {
        print("Persona completed")
        identificationContinuation?.resume(returning: .completed)
        identificationContinuation = nil
    }
    
    public func inquiryCanceled(inquiryId: String?, sessionToken: String?) {
        print("Persona canceled")
        identificationContinuation?.resume(returning: .cancelled)
        identificationContinuation = nil
    }
    
    public func inquiryError(_ error: Error) {
        print("Inquiry error")
        identificationContinuation?.resume(throwing: KycDaoError.persona(error))
        identificationContinuation = nil
    }
    
}
