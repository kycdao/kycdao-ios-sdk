//
//  File.swift
//  
//
//  Created by Vekety Robin on 2022. 06. 20..
//

import Foundation
import UIKit

class CreateSignatureViewController: UIViewController {
    
    let walletIconView = UIImageView()
    let accountAddress = UILabel()
    let createSignatureTitle = UILabel()
    let createSignatureMessage = UILabel()
    let dataBackground = UIView()
    let dataLabel = UILabel()
    let createSignatureButton = SimpleButton()
    let containerView = UIView()
    
    private var walletSession: WalletSession
    private var kycSession: KYCSession
    
    init(walletSession: WalletSession, kycSession: KYCSession) {
        self.walletSession = walletSession
        self.kycSession = kycSession
        super.init(nibName: nil, bundle: nil)
        
        accountAddress.text = kycSession.walletAddress
        createSignatureButton.addTarget(self, action: #selector(createSignatureTap(_:)), for: .touchUpInside)
        
        Task { @MainActor in
            do {
                
                if let imageURL = walletSession.icon {
                    typealias ImageResult = (data: Data, response: URLResponse)?
                    let imageResult: ImageResult = try? await URLSession.shared.data(from: imageURL)
                    if let data = imageResult?.data {
                        walletIconView.image = UIImage(data: data)
                    }
                }
                
//                dataLabel.text = kycSession.loginProof
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
        
        walletIconView.clipsToBounds = true
        walletIconView.layer.cornerRadius = 20
        
        accountAddress.textAlignment = .center
        accountAddress.lineBreakMode = .byCharWrapping
        accountAddress.numberOfLines = 0
        accountAddress.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        accountAddress.textColor = .systemGray4
        
        createSignatureTitle.font = .systemFont(ofSize: 18, weight: .semibold)
        createSignatureTitle.textAlignment = .center
        
        createSignatureMessage.lineBreakMode = .byWordWrapping
        createSignatureMessage.numberOfLines = 0
        createSignatureMessage.textAlignment = .center
        
        dataBackground.backgroundColor = .systemGray5
        dataBackground.clipsToBounds = true
        dataBackground.layer.cornerRadius = 4
        
        dataLabel.lineBreakMode = .byCharWrapping
        dataLabel.numberOfLines = 0
        dataLabel.font = .monospacedSystemFont(ofSize: 16, weight: .regular)
        
        view.addSubview(containerView)
        view.addSubview(accountAddress)
        containerView.addSubview(walletIconView)
        containerView.addSubview(createSignatureTitle)
        containerView.addSubview(createSignatureMessage)
        containerView.addSubview(dataBackground)
        dataBackground.addSubview(dataLabel)
        containerView.addSubview(createSignatureButton)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        walletIconView.translatesAutoresizingMaskIntoConstraints = false
        accountAddress.translatesAutoresizingMaskIntoConstraints = false
        createSignatureTitle.translatesAutoresizingMaskIntoConstraints = false
        createSignatureMessage.translatesAutoresizingMaskIntoConstraints = false
        dataBackground.translatesAutoresizingMaskIntoConstraints = false
        dataLabel.translatesAutoresizingMaskIntoConstraints = false
        createSignatureButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            containerView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            accountAddress.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            accountAddress.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            accountAddress.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            accountAddress.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            walletIconView.topAnchor.constraint(equalTo: containerView.topAnchor),
            walletIconView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            walletIconView.widthAnchor.constraint(equalToConstant: 80),
            walletIconView.heightAnchor.constraint(equalToConstant: 80),
            
            createSignatureTitle.topAnchor.constraint(equalTo: walletIconView.bottomAnchor, constant: 16),
            createSignatureTitle.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            createSignatureTitle.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            createSignatureTitle.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            createSignatureMessage.topAnchor.constraint(equalTo: createSignatureTitle.bottomAnchor, constant: 4),
            createSignatureMessage.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            createSignatureMessage.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            createSignatureMessage.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            dataBackground.topAnchor.constraint(equalTo: createSignatureMessage.bottomAnchor, constant: 8),
            dataBackground.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 16),
            dataBackground.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -16),
            dataBackground.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            dataLabel.topAnchor.constraint(equalTo: dataBackground.topAnchor, constant: 4),
            dataLabel.leadingAnchor.constraint(equalTo: dataBackground.leadingAnchor, constant: 8),
            dataLabel.bottomAnchor.constraint(equalTo: dataBackground.bottomAnchor, constant: -4),
            dataLabel.trailingAnchor.constraint(equalTo: dataBackground.trailingAnchor, constant: -8),
            
            createSignatureButton.topAnchor.constraint(equalTo: dataBackground.bottomAnchor, constant: 16),
            createSignatureButton.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            createSignatureButton.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            createSignatureButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            createSignatureButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            createSignatureButton.heightAnchor.constraint(equalToConstant: 40),
            createSignatureButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.7),
        ])
        
        
        var signButtonText: String = "Sign"
        
        signButtonText = "Sign with \(walletSession.name)"
        
        createSignatureTitle.text = "Create signature"
        createSignatureMessage.text = "Your next step is to create a signature with your wallet\n\nThe data you will sign with your wallet:"
        createSignatureButton.setTitle(signButtonText, for: .normal)
    }
    
    @objc func createSignatureTap(_ sender: Any) {

        Task {
            do {
                
                try await kycSession.login()
                
                if kycSession.requiredInformationProvided {
                    
                    if kycSession.emailConfirmed {
                        
                        switch kycSession.verificationStatus {
                        case .verified:
                            Page.currentPage.send(.selectNFTImage(walletSession: walletSession, kycSession: kycSession))
                        case .processing:
                            Page.currentPage.send(.personaCompletePage(walletSession: walletSession, kycSession: kycSession))
                        case .notVerified:
                            Page.currentPage.send(.personaVerification(walletSession: walletSession, kycSession: kycSession))
                        }
                        
                    } else {
                        
                        Page.currentPage.send(.confirmEmail(walletSession: walletSession, kycSession: kycSession))
                    }
                    
                } else {
                    
                    Page.currentPage.send(.informationRequest(walletSession: walletSession, kycSession: kycSession))
                }
            } catch let error {
                print("Failed KYC login \(error)")
            }
        }
        
    }
    
}
