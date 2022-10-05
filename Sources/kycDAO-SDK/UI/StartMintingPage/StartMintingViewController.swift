//
//  StartMintingViewController.swift
//  
//
//  Created by Vekety Robin on 2022. 06. 22..
//

import Foundation
import UIKit

class StartMintingViewController: UIViewController {
    
    let containerView = UIView()
    let titleLabel = UILabel()
    let messageLabel = UILabel()
    let startMintingButton = SimpleButton()
    
    let walletSession: WalletSession
    let kycSession: KYCSession
    
    init(walletSession: WalletSession, kycSession: KYCSession) {
        self.walletSession = walletSession
        self.kycSession = kycSession
        super.init(nibName: nil, bundle: nil)
        startMintingButton.addTarget(self, action: #selector(startMintingButtonTap(_:)), for: .touchUpInside)
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
        containerView.addSubview(startMintingButton)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        startMintingButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            messageLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            startMintingButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
            startMintingButton.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            startMintingButton.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            startMintingButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            startMintingButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            startMintingButton.heightAnchor.constraint(equalToConstant: 40),
            startMintingButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8)
        ])
        
        titleLabel.text = "Mint your NFT"
        messageLabel.text = "Start minting your KYC NFT here"
        startMintingButton.setTitle("Exit", for: .normal)
    }
    
    @objc func startMintingButtonTap(_ sender: Any) {
        
//        Task {
//            let authorization = try await kycSession.requestMinting()
//            print(authorization)
//            guard let txHash = authorization.tx_hash else {
//                print("No tx hash")
//                return
//            }
//            walletSession.getTransactionReceipt(txHash: "0x80360bfe05fcb0aa05cefe88834abb133b0f14b38b0a459cc67ad79e88a280be")
//            try await kycSession.getTransactionReceipt(hash: "0x80360bfe05fcb0aa05cefe88834abb133b0f14b38b0a459cc67ad79e88a280be")
//        }
        Page.currentPage.send(.selectNFTImage(walletSession: walletSession, kycSession: kycSession))
        
    }
    
    
}
