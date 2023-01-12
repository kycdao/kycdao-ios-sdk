//
//  File.swift
//  
//
//  Created by Vekety Robin on 2023. 01. 11..
//

import Foundation
import web3
import BigInt

extension VerificationSession {
    
    @discardableResult
    func refreshUser() async throws -> User {
        
        let result = try await ApiConnection.call(endPoint: .user,
                                                  method: .GET,
                                                  output: UserDTO.self)
        let updatedUser = User(dto: result.data)
        sessionData.user = updatedUser
        return updatedUser
        
    }
    
    @discardableResult
    func refreshSession() async throws -> BackendSessionData {
        
        let result = try await ApiConnection.call(endPoint: .session,
                                                  method: .GET,
                                                  output: BackendSessionDataDTO.self)
        let updatedSession = BackendSessionData(dto: result.data)
        sessionData = updatedSession
        return updatedSession
        
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
    
    func getRawRequiredMintCostForCode(authCode: String) async throws -> BigUInt {
        
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
    
    func getRequiredMintCostForCode(authCode: String) async throws -> BigUInt {
        let mintingCost = try await getRawRequiredMintCostForCode(authCode: authCode)
        
        //Adding 10% slippage (no floating point operation for multiplying BigUInt with 1.1)
        let result = mintingCost.quotientAndRemainder(dividingBy: 10)
        let slippage = result.quotient
        
        return mintingCost + slippage
    }
    
    func getRequiredMintCostForYears(_ years: UInt32) async throws -> BigUInt {
        
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
    
    func estimateGas(forTransaction transaction: EthereumTransaction) async throws -> GasEstimation {
            
        //price in wei
        let ethGasPrice = try await ethereumClient.eth_gasPrice()
        let minGasPrice = BigUInt(50).gwei
        let price = max(ethGasPrice, minGasPrice)
        
        let amount = try await ethereumClient.eth_estimateGas(transaction)
        
        let estimation = GasEstimation(gasCurrency: networkMetadata.nativeCurrency,
                                       amount: amount,
                                       price: ethGasPrice)
        
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
