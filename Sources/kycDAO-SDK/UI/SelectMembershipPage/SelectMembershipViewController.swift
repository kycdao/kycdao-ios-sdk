//
//  SelectMembershipViewController.swift
//  
//
//  Created by Vekety Robin on 2022. 12. 02..
//

import Foundation
import UIKit

class SelectMembershipViewController: UIViewController {
    
    let kycDAOIconView = UIImageView()
    
    let mintMembershipTitle = UILabel()
    let membershipPriceLabel = UILabel()
    let membershipPrice = UILabel()
    let discountYearsLabel = UILabel()
    let membershipPeriodLabel = UILabel()
    let membershipPeriod = UILabel()
    let membershipPeriodStepper = UIStepper()
    let totalMembershipCost = UILabel()
    
    let selectMembership = SimpleButton()
    
    let containerView = UIView()
    
    private var walletSession: WalletConnectSession
    private var verificationSession: VerificationSession
    private var membershipPricePerYear: UInt32?
    
    init(walletSession: WalletConnectSession, verificationSession: VerificationSession) {
        self.walletSession = walletSession
        self.verificationSession = verificationSession
        super.init(nibName: nil, bundle: nil)
        
        selectMembership.addTarget(self, action: #selector(selectMembershipTap(_:)), for: .touchUpInside)
        
        Task { @MainActor in
            do {
                
                if let imageURL = URL(string: "https://avatars.githubusercontent.com/u/87816891?s=200&v=4") {
                    typealias ImageResult = (data: Data, response: URLResponse)?
                    let imageResult: ImageResult = try? await URLSession.shared.data(from: imageURL)
                    if let data = imageResult?.data {
                        kycDAOIconView.image = UIImage(data: data)
                    }
                }
                
            } catch {
                print("Failed to create session")
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        kycDAOIconView.clipsToBounds = true
        kycDAOIconView.layer.cornerRadius = 20
        
        mintMembershipTitle.font = .systemFont(ofSize: 30, weight: .semibold)
        
        membershipPriceLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        membershipPeriodLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        discountYearsLabel.font = .systemFont(ofSize: 12)
        totalMembershipCost.font = .systemFont(ofSize: 24, weight: .semibold)
        
        membershipPeriodStepper.minimumValue = 1
        membershipPeriodStepper.maximumValue = 100
        
        view.addSubview(containerView)
        containerView.addSubview(kycDAOIconView)
        containerView.addSubview(mintMembershipTitle)
        containerView.addSubview(membershipPriceLabel)
        containerView.addSubview(membershipPrice)
        containerView.addSubview(discountYearsLabel)
        containerView.addSubview(membershipPeriodLabel)
        containerView.addSubview(membershipPeriod)
        containerView.addSubview(membershipPeriodStepper)
        containerView.addSubview(totalMembershipCost)
        containerView.addSubview(selectMembership)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        kycDAOIconView.translatesAutoresizingMaskIntoConstraints = false
        mintMembershipTitle.translatesAutoresizingMaskIntoConstraints = false
        membershipPriceLabel.translatesAutoresizingMaskIntoConstraints = false
        membershipPrice.translatesAutoresizingMaskIntoConstraints = false
        discountYearsLabel.translatesAutoresizingMaskIntoConstraints = false
        membershipPeriodLabel.translatesAutoresizingMaskIntoConstraints = false
        membershipPeriod.translatesAutoresizingMaskIntoConstraints = false
        membershipPeriodStepper.translatesAutoresizingMaskIntoConstraints = false
        totalMembershipCost.translatesAutoresizingMaskIntoConstraints = false
        selectMembership.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            kycDAOIconView.topAnchor.constraint(equalTo: containerView.topAnchor),
            kycDAOIconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            kycDAOIconView.widthAnchor.constraint(equalToConstant: 60),
            kycDAOIconView.heightAnchor.constraint(equalToConstant: 60),
            
            mintMembershipTitle.centerYAnchor.constraint(equalTo: kycDAOIconView.centerYAnchor),
            mintMembershipTitle.leadingAnchor.constraint(equalTo: kycDAOIconView.trailingAnchor, constant: 8),
            mintMembershipTitle.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),
            
            membershipPriceLabel.topAnchor.constraint(equalTo: kycDAOIconView.bottomAnchor, constant: 16),
            membershipPriceLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            membershipPriceLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),
            
            membershipPrice.topAnchor.constraint(equalTo: membershipPriceLabel.bottomAnchor, constant: 4),
            membershipPrice.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            membershipPrice.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),
            
            membershipPeriodLabel.topAnchor.constraint(equalTo: membershipPrice.bottomAnchor, constant: 12),
            membershipPeriodLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            membershipPeriodLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),
            
            membershipPeriod.topAnchor.constraint(equalTo: membershipPeriodLabel.bottomAnchor, constant: 4),
            membershipPeriod.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            membershipPeriod.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),
            
            membershipPeriodStepper.bottomAnchor.constraint(equalTo: membershipPeriod.bottomAnchor, constant: -4),
            membershipPeriodStepper.leadingAnchor.constraint(greaterThanOrEqualTo: membershipPeriod.trailingAnchor, constant: 8),
            membershipPeriodStepper.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            totalMembershipCost.topAnchor.constraint(equalTo: membershipPeriod.bottomAnchor, constant: 32),
            totalMembershipCost.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 16),
            totalMembershipCost.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),
            totalMembershipCost.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            discountYearsLabel.topAnchor.constraint(equalTo: totalMembershipCost.bottomAnchor, constant: 12),
            discountYearsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 16),
            discountYearsLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),
            discountYearsLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            selectMembership.topAnchor.constraint(equalTo: discountYearsLabel.bottomAnchor, constant: 32),
            selectMembership.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            selectMembership.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            selectMembership.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor),
            selectMembership.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            selectMembership.heightAnchor.constraint(equalToConstant: 40),
            selectMembership.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.7),
        ])
        
        mintMembershipTitle.text = "Mint membership"
        discountYearsLabel.text = "No discounts"
        membershipPeriodLabel.text = "Membership period"
        membershipPeriod.text = "1 year"
        membershipPriceLabel.text = "Membership price"
        membershipPrice.text = "- / year"
        totalMembershipCost.text = "-"
        
        selectMembership.setTitle("Select membership", for: .normal)
        
        membershipPeriodStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)
        
        Task {
            let price = try await verificationSession.getMembershipCostPerYear()
            membershipPrice.text = "$\(price) / year"
            await updateTotalCost(years: 1)
        }
    }
    
    @objc func stepperValueChanged(_ sender: UIStepper!) {
        let years = UInt32(sender.value)
        membershipPeriod.text = years == 1 ? "1 year" : "\(years) years"
        Task {
            await updateTotalCost(years: years)
        }
    }
    
    private func updateTotalCost(years: UInt32) async {
        let estimation = try? await verificationSession.paymentEstimation(yearsPurchased: years)
        guard let estimation else { return }
        totalMembershipCost.text = estimation.paymentAmount == 0 ? "Free" : estimation.paymentAmountText
        discountYearsLabel.text = estimation.discountYears == 0 ? "No discounts" : "Discounted years applied: \(estimation.discountYears)"
    }
    
    @objc func selectMembershipTap(_ sender: Any) {

        Page.currentPage.send(.selectNFTImage(walletSession: walletSession, verificationSession: verificationSession, membershipDuration: 2))
        
    }
    
}
