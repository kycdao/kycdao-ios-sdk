//
//  MintingInProgressViewController.swift
//  
//
//  Created by Vekety Robin on 2022. 10. 13..
//

import Foundation
import UIKit

class MintingInProgressViewController: UIViewController {
    
    private var walletSession: WalletConnectSession
    private var kycSession: VerificationSession
    
    let containerView = UIView()
    let titleLabel = UILabel()
    let messageLabel = UILabel()
    let topActionButton = SimpleButton(style: .outline)
    let bottomActionButton = SimpleButton()
    let activityIndicator = UIActivityIndicatorView()
    
    private var mintingResult: Result<URL?, Error>?
    
    init(walletSession: WalletConnectSession, kycSession: VerificationSession) {
        self.walletSession = walletSession
        self.kycSession = kycSession
        super.init(nibName: nil, bundle: nil)
        
        topActionButton.addTarget(self, action: #selector(topActionButtonTapped(_:)), for: .touchUpInside)
        bottomActionButton.addTarget(self, action: #selector(bottomActionButtonTapped(_:)), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        
        view.backgroundColor = .systemBackground
        
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(activityIndicator)
        containerView.addSubview(topActionButton)
        containerView.addSubview(bottomActionButton)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        topActionButton.translatesAutoresizingMaskIntoConstraints = false
        bottomActionButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            messageLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            activityIndicator.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            activityIndicator.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            activityIndicator.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
//            activityIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            topActionButton.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            topActionButton.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            topActionButton.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            topActionButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            topActionButton.heightAnchor.constraint(equalToConstant: 40),
            topActionButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.7),
            
            bottomActionButton.topAnchor.constraint(equalTo: topActionButton.bottomAnchor, constant: 16),
            bottomActionButton.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            bottomActionButton.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            bottomActionButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bottomActionButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bottomActionButton.heightAnchor.constraint(equalToConstant: 40),
            bottomActionButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.7),
        ])
        
        titleLabel.text = "Minting NFT..."
        messageLabel.text = "Please wait for the minting process to complete"
        topActionButton.isHidden = true
        bottomActionButton.isHidden = true
        
        activityIndicator.startAnimating()
        
        mintNFT()
    }
    
    func mintNFT() {
        Task { @MainActor in
            do {
                let txURL = try await kycSession.mint()
                activityIndicator.stopAnimating()
                titleLabel.text = "Minting successful 🎉"
                messageLabel.text = "Congratulations, your KYC NFT is ready!"
                
                bottomActionButton.isHidden = false
                bottomActionButton.setTitle("Exit", for: .normal)
                
                guard let txURL = txURL else {
                    mintingResult = .success(nil)
                    return
                }

                messageLabel.text = "Congratulations, your KYC NFT is ready! You can view your transaction or close the KYC flow now."
                topActionButton.isHidden = false
                topActionButton.setTitle("Show transaction", for: .normal)
                
                mintingResult = .success(txURL)
                
            } catch let error {
                activityIndicator.stopAnimating()
                titleLabel.text = "Minting failed ☹️"
                messageLabel.text = "Something went wrong during the minting process"

                topActionButton.isHidden = false
                topActionButton.setTitle("Retry", for: .normal)
                mintingResult = .failure(error)
            }
        }
    }
    
    @objc func topActionButtonTapped(_ sender: Any) {
        
        guard let mintingResult = mintingResult else {
            return
        }
        
        switch mintingResult {
        case .success(let transactionURL):
            guard let transactionURL = transactionURL else { return }
            UIApplication.shared.open(transactionURL)
        case .failure:
            titleLabel.text = "Minting NFT..."
            messageLabel.text = "Please wait for the minting process to complete"
            topActionButton.isHidden = true
            bottomActionButton.isHidden = true
            activityIndicator.startAnimating()
            mintNFT()
        }
        
    }
    
    @objc func bottomActionButtonTapped(_ sender: Any) {
        
        Page.currentPage.send(.exit)
        
    }
    
}

