//
//  PersonaViewController.swift
//  
//
//  Created by Vekety Robin on 2022. 06. 21..
//

import Foundation
import UIKit
import Persona2
import Combine

class PersonaViewController: UIViewController {
    
    private var disposeBag = Set<AnyCancellable>()
    
    let containerView = UIView()
    let titleLabel = UILabel()
    let messageLabel = UILabel()
    let startPersonaButton = SimpleButton()
    
    private var walletSession: WalletConnectSession
    private var kycSession: KYCSession
    
    init(walletSession: WalletConnectSession, kycSession: KYCSession) {
        self.walletSession = walletSession
        self.kycSession = kycSession
        super.init(nibName: nil, bundle: nil)
        startPersonaButton.addTarget(self, action: #selector(personaButtonTap(_:)), for: .touchUpInside)
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
        containerView.addSubview(startPersonaButton)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        startPersonaButton.translatesAutoresizingMaskIntoConstraints = false
        
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
            
            startPersonaButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
            startPersonaButton.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            startPersonaButton.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            startPersonaButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            startPersonaButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            startPersonaButton.heightAnchor.constraint(equalToConstant: 40),
            startPersonaButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8)
        ])
        
        titleLabel.text = "Idenitity verification"
        messageLabel.text = "Your identity verification with Persona begins here"
        startPersonaButton.setTitle("Start", for: .normal)
    }
    
    @objc func personaButtonTap(_ sender: Any) {
        
        Task { @MainActor in
            let status = try await kycSession.startIdentification(fromViewController: self)
            switch status {
            case .completed:
                Page.currentPage.send(.personaCompletePage(walletSession: walletSession, kycSession: kycSession))
            case .cancelled:
                print("Persona flow cancelled")
            }
        }
        
    }
    
}
