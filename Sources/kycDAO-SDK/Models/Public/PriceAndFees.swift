//
//  PriceAndFees.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 09..
//

import Foundation
import BigInt

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
    public let gasFee: BigUInt
    
    /// The currency used by the network
    public let currency: CurrencyData
    
    /// The full price of the transaction
    public var fullPrice: BigUInt {
        paymentAmount + gasFee
    }
    
    /// `paymentAmount` in an easy to display string representation including currency symbol
    public var paymentAmountText: String {
        let baseToNativeDivisor = currency.baseToNativeDivisor
        let symbol = currency.symbol
        return paymentAmount.decimalText(divisor: baseToNativeDivisor) + " \(symbol)"
    }
    
    /// Gas fee estimation in an easy to display string representation including currency symbol
    public var gasFeeText: String {
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
