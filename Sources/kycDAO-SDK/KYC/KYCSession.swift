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

public class KYCSession: Identifiable {
    
    public let id = UUID().uuidString
    private let personaInquiryTemplateId = "itmpl_bWGWAeN5fDcv5PLqLwFhKxP6"
    private let infuraProjectId = "8edae24121f74398b57da7ff5a3729a4"
    
    private var identificationContinuation: CheckedContinuation<IdentityFlowResult, Error>?
    
    private var sessionData: KYCSessionData
    
    public var walletAddress: String
    
    public var kycConfig: SmartContractConfig?
    public var accreditedConfig: SmartContractConfig?
    
    public var loginProof: String {
        "kycDAO-login-\(sessionData.nonce)"
    }
    
    public var isLoggedIn: Bool {
        sessionData.user != nil
    }
    
    public var emailAddress: String? {
        sessionData.user?.email
    }
    
    private var personaStatus: PersonaStatus {
        get async throws {
            let apiStatus = try await KYCManager.shared.apiStatus()
            
            guard let personaStatus = apiStatus.persona
            else {
                throw KYCError.genericError
            }
            
            return personaStatus
        }
    }
    
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
    
    public var residency: String? {
        sessionData.user?.residency
    }
    
    public var residencyProvided: Bool {
        residency?.isEmpty == false
    }
    
    public var emailProvided: Bool {
        emailAddress?.isEmpty == false
    }
    
    public var disclaimerAccepted: Bool {
        sessionData.user?.disclaimer_accepted?.isEmpty == false
    }
    
    public var legalEntityStatus: Bool {
        sessionData.user?.legal_entity == true
    }
    
    public var requiredInformationProvided: Bool {
        residencyProvided && emailProvided && disclaimerAccepted && sessionData.user?.legal_entity != nil
    }
    
    private var authCode: String?
    
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
    
    public let walletSession: WalletSessionProtocol
    private let networkMetadata: NetworkMetadata
    
    public var chainId: String {
        networkMetadata.caip2id
    }
    
    init(walletAddress: String,
         walletSession: WalletSessionProtocol,
         kycConfig: SmartContractConfig?,
         accreditedConfig: SmartContractConfig?,
         data: KYCSessionData,
         networkMetadata: NetworkMetadata) {
        self.walletAddress = walletAddress
        self.sessionData = data
        self.walletSession = walletSession
        self.kycConfig = kycConfig
        self.accreditedConfig = accreditedConfig
        self.networkMetadata = networkMetadata
    }
    
    public func login() async throws {
        
        let signature = try await walletSession.personalSign(walletAddress: walletAddress, message: loginProof)
        
        let appState = await UIApplication.shared.applicationState
        var state = appState == .active ? "active" : (appState == .background ? "background" : "inactive")
        print("appState \(state) mainThread: \(Thread.isMainThread)")
        
        let signatureInput = SignatureInputDTO(signature: signature,
                                               public_key: nil)
        
        let result = try await KYCConnection.call(endPoint: .user,
                                                  method: .POST,
                                                  input: signatureInput,
                                                  output: KYCUserDTO.self)
        
        sessionData.user = KYCUser(dto: result.data)
        
    }
    
    @discardableResult
    private func refreshUser() async throws -> KYCUser {
        
        let result = try await KYCConnection.call(endPoint: .user,
                                                  method: .GET,
                                                  output: KYCUserDTO.self)
        let updatedUser = KYCUser(dto: result.data)
        sessionData.user = updatedUser
        return updatedUser
        
    }
    
    public func acceptDisclaimer() async throws {
        
        do {
        
            let _ = try await KYCConnection.call(endPoint: .disclaimer, method: .POST)
        
        } catch KYCError.httpStatusCode(_, let data) {
        
            let serverError = try JSONDecoder().decode(KYCErrorResponse.self, from: data)
            
            guard let errorCode = serverError.error_code else {
                throw KYCError.genericError
            }
            
            switch errorCode {
            case .disclaimerAlreadyAccepted:
                return
            }
            
            throw KYCError.genericError
            
        } catch let error {
            throw error
        }
        
        try await refreshUser()
        
    }
    
    public func updateUser(email: String, residency: String, legalEntity: Bool) async throws {
        
        let userUpdateInput = UserUpdateInput(email: email,
                                              residency: residency,
                                              legalEntity: legalEntity)
        
        let result = try await KYCConnection.call(endPoint: .user,
                                                  method: .PUT,
                                                  input: userUpdateInput,
                                                  output: KYCUserDTO.self)
        
        sessionData.user = KYCUser(dto: result.data)
        
    }
    
    public func sendConfirmationEmail() async throws {
        try await KYCConnection.call(endPoint: .emailConfirmation, method: .POST)
    }
    
    public func continueWhenEmailConfirmed() async {
        
        var emailConfirmed = false
        
        while !emailConfirmed {
            // Delay the task by 3 second
            try? await Task.sleep(nanoseconds: 1_000_000_000 * 3)
            let user = try? await refreshUser()
            emailConfirmed = user?.email_confirmed?.isEmpty == false
        }
        
    }
    
    @MainActor
    public func startIdentification(fromViewController viewController: UIViewController) async throws -> IdentityFlowResult {
        
        guard let referenceId = sessionData.user?.ext_id else {
            throw KYCError.genericError
        }
        
        let personaStatus = try await personaStatus
        
        guard let templateId = personaStatus.template_id
        else {
            throw KYCError.genericError
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
    
    public func continueWhenIdentified() async {
        
        var identified = false
        
        while !identified {
            
            // Delay the task by 3 second
            try? await Task.sleep(nanoseconds: 1_000_000_000 * 3)
            let user = try? await refreshUser()
            
            if let verificationRequests = user?.verification_requests {
                identified = verificationRequests.contains {
                    $0.verification_type == .kyc && $0.status == .verified
                }
            }
        }
    }
    
    public func getNFTImages() -> [TokenImage] {
        print(sessionData.user?.availableImages ?? [:])
        
        return sessionData.user?.availableImages
            .filter { $0.imageType == .identicon } ?? []
        
    }
    
    public func requestMinting(selectedImageId: String) async throws {
        
        guard let accountId = sessionData.user?.blockchain_accounts?.first?.id
        else { throw KYCError.genericError }
        
        let mintAuthInput = MintRequestInput(accountId: accountId,
                                             network: networkMetadata.id,
                                             selectedImageId: selectedImageId)
        
        let result = try await KYCConnection.call(endPoint: .authorizeMinting,
                                                  method: .POST,
                                                  input: mintAuthInput,
                                                  output: MintAuthorization.self)
        let mintAuth = result.data
        
        guard let code = mintAuth.code, let txHash = mintAuth.tx_hash else {
            throw KYCError.genericError
        }
        
        authCode = code
        
        try await continueWhenTransactionFinished(txHash: txHash)
        
    }
    
    @discardableResult
    func continueWhenTransactionFinished(txHash: String) async throws -> EthereumTransactionReceipt {
        
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
        
        throw KYCError.genericError
        
    }
    
    public func getTransactionReceipt(txHash: String) async throws -> EthereumTransactionReceipt {
        
        let projectID = "8edae24121f74398b57da7ff5a3729a4"
        
        print("getTransactionReceipt")
        
        guard let clientUrl = URL(string: "https://polygon-mumbai.infura.io/v3/\(projectID)") else {
            throw KYCError.genericError
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
            throw KYCError.genericError
        }
        
        let contractAddress = EthereumAddress(resolvedContractAddress)
        let ethWalletAddress = EthereumAddress(walletAddress)
        
        return KYCMintingFunction(contract: contractAddress,
                                  authCode: authCodeNumber,
                                  from: ethWalletAddress,
                                  gasPrice: nil,
                                  gasLimit: nil)
    }
    
    public func mint() async throws {
        
        print("MINTING...")
        
        try await refreshUser()
        
        guard let authCode = authCode
        else { throw KYCError.unauthorizedMinting }
        
        guard let accountId = sessionData.user?.blockchain_accounts?.first?.id
        else { throw KYCError.genericError }
        
        let mintingFunction = try kycMintingFunction(authCode: authCode)
        let props = try await transactionProperties(forFunction: mintingFunction)
        let txHash = try await walletSession.sendMintingTransaction(walletAddress: walletAddress, mintingProperties: props)
        let receipt = try await continueWhenTransactionFinished(txHash: txHash)
        
        guard let event = receipt.lookForEvent(event: ERC721Events.Transfer.self)
        else { throw KYCError.genericError }
        
        try await tokenMinted(authCode: authCode, tokenId: "\(event.tokenId)", txHash: txHash)
        
        self.authCode = nil
        
    }
    
    func transactionProperties(forFunction function: ABIFunction) async throws -> MintingProperties {
        
        let estimation = try await estimateGas(forFunction: function)
        guard let transactionData = try function.transaction().data?.web3.hexString
        else {
            throw KYCError.genericError
        }
        
        return MintingProperties(contractAddress: function.contract.value,
                                 contractABI: transactionData,
                                 gasAmount: estimation.amount.web3.hexString,
                                 gasPrice: estimation.price.web3.hexString)
        
    }
    
    public func estimateGasForMinting() async throws -> GasEstimation {
        
        guard let authCode = authCode
        else { throw KYCError.unauthorizedMinting }
        
        let mintingFunction = try kycMintingFunction(authCode: authCode)
        
        return try await estimateGas(forFunction: mintingFunction)
        
    }
    
    func estimateGas(forFunction function: ABIFunction) async throws -> GasEstimation {
        
        print("estimateGas")
        
        guard let clientUrl = URL(string: "https://polygon-mumbai.infura.io/v3/\(infuraProjectId)") else {
            throw KYCError.genericError
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
        
        try await KYCConnection.call(endPoint: .token, method: .POST, input: mintResultInput)
        
    }
    
}

extension KYCSession: InquiryDelegate {
    
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
        identificationContinuation?.resume(throwing: KYCError.persona(error))
        identificationContinuation = nil
    }
    
}
