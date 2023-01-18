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
    
    func getRawRequiredMintCostForCode(authCode: UInt32) async throws -> BigUInt {
        
        let ethWalletAddress = EthereumAddress(walletAddress)
        let mintCost = try await kycContract.getRequiredMintCostForCode(authorizationCode: authCode,
                                                                        destination: ethWalletAddress)
        
        return mintCost
    }
    
    func getRequiredMintCostForCode(authCode: UInt32) async throws -> BigUInt {
        let mintingCost = try await getRawRequiredMintCostForCode(authCode: authCode)
        
        //Adding 10% slippage (no floating point operation for multiplying BigUInt with 1.1)
        let result = mintingCost.quotientAndRemainder(dividingBy: 10)
        let slippage = result.quotient
        
        return mintingCost + slippage
    }
    
    func getRequiredMintCostForYears(_ years: UInt32) async throws -> BigUInt {
        
        guard years >= 1
        else { throw KycDaoError.internal(.unknown) }
        
        let discountYears = sessionData.discountYears ?? 0
        let yearsToPayFor = years - discountYears
        let yearsInSeconds = yearsToPayFor * 365 * 24 * 60 * 60
        
        return try await kycContract.getRequiredMintCostForSeconds(seconds: yearsInSeconds)
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
        let amount = try await ethereumClient.eth_estimateGas(transaction)
        
        let estimation = GasEstimation(gasCurrency: networkMetadata.nativeCurrency,
                                       amount: amount,
                                       price: ethGasPrice)
        
        return estimation
    }
    
    func tokenMinted(authCode: UInt32, tokenId: BigUInt, txHash: String) async throws -> TokenDetailsDTO {
        
        let mintResultInput = MintResultUploadDTO(authCode: "\(authCode)",
                                                  tokenId: "\(tokenId)",
                                                  txHash: txHash)
        
        let result = try await ApiConnection.call(endPoint: .token,
                                                  method: .POST,
                                                  input: mintResultInput,
                                                  output: TokenDetailsDTO.self)
        
        return result.data
        
    }
    
}
