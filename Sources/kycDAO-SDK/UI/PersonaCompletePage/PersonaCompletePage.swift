//
//  PersonaCompletePage.swift
//  
//
//  Created by Vekety Robin on 2022. 07. 21..
//

import Foundation
import UIKit

class PersonaCompleteViewController: UIViewController {
    
    private var walletSession: WalletConnectSession
    private var kycSession: KYCSession
    
    let containerView = UIView()
    let titleLabel = UILabel()
    let messageLabel = UILabel()
    let activityIndicator = UIActivityIndicatorView()
    
    init(walletSession: WalletConnectSession, kycSession: KYCSession) {
        self.walletSession = walletSession
        self.kycSession = kycSession
        super.init(nibName: nil, bundle: nil)
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
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
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
            activityIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        
        titleLabel.text = "Your identification is being verified"
        messageLabel.text = "The minting process will begin in any moment"
        
        activityIndicator.startAnimating()
        
        Task {
            try await kycSession.resumeWhenIdentified()
            Page.currentPage.send(.selectNFTImage(walletSession: walletSession, kycSession: kycSession))
        }
    }
    
}
