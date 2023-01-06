//
//  ConfirmEmailViewController.swift
//  
//
//  Created by Vekety Robin on 2022. 07. 08..
//

import Foundation
import UIKit
import KycDao

class ConfirmEmailViewController : UIViewController, UITextFieldDelegate {
    
    private var walletSession: WalletConnectSession
    private var verificationSession: VerificationSession
    
    let containerView = UIView()
    let titleLabel = UILabel()
    let messageLabel = UILabel()
    let activityIndicator = UIActivityIndicatorView()
    let emailField = UITextField()
    let emailSeparator = UIView()
    let emailChangeSuccessSign = UIImageView(image: UIImage(systemName: "checkmark.circle"))
    
    let notReceivingEmailLabel = UILabel()
    let resendEmailButton = SimpleButton(style: .filled)
    let changeEmailButton = SimpleButton(style: .outline)
    
    init(walletSession: WalletConnectSession, verificationSession: VerificationSession) {
        self.walletSession = walletSession
        self.verificationSession = verificationSession
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
        
        notReceivingEmailLabel.font = .systemFont(ofSize: 12)
        notReceivingEmailLabel.textColor = .systemGray2
        
        emailSeparator.backgroundColor = .systemGray5
        emailChangeSuccessSign.tintColor = .systemGreen
        emailChangeSuccessSign.isHidden = true
        
        emailField.delegate = self
        
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(emailField)
        containerView.addSubview(emailChangeSuccessSign)
        containerView.addSubview(emailSeparator)
        containerView.addSubview(activityIndicator)
        
        view.addSubview(notReceivingEmailLabel)
        view.addSubview(resendEmailButton)
        view.addSubview(changeEmailButton)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        emailField.translatesAutoresizingMaskIntoConstraints = false
        emailChangeSuccessSign.translatesAutoresizingMaskIntoConstraints = false
        emailSeparator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        resendEmailButton.translatesAutoresizingMaskIntoConstraints = false
        changeEmailButton.translatesAutoresizingMaskIntoConstraints = false
        notReceivingEmailLabel.translatesAutoresizingMaskIntoConstraints = false
        
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
            
            emailField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            emailField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            emailField.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            
            emailChangeSuccessSign.centerYAnchor.constraint(equalTo: emailField.centerYAnchor),
            emailChangeSuccessSign.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            emailChangeSuccessSign.widthAnchor.constraint(equalToConstant: 22),
            emailChangeSuccessSign.heightAnchor.constraint(equalToConstant: 22),
            
            emailSeparator.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -32),
            emailSeparator.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 4),
            emailSeparator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            emailSeparator.heightAnchor.constraint(equalToConstant: 1),
            
            activityIndicator.topAnchor.constraint(equalTo: emailSeparator.bottomAnchor, constant: 20),
            activityIndicator.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            activityIndicator.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            notReceivingEmailLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            notReceivingEmailLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: 16),
            notReceivingEmailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            notReceivingEmailLabel.topAnchor.constraint(greaterThanOrEqualTo: containerView.bottomAnchor, constant: 20),
            
            resendEmailButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            resendEmailButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            resendEmailButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resendEmailButton.heightAnchor.constraint(equalToConstant: 40),
            resendEmailButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            resendEmailButton.topAnchor.constraint(equalTo: notReceivingEmailLabel.bottomAnchor, constant: 12),
            
            changeEmailButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            changeEmailButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            changeEmailButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            changeEmailButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            changeEmailButton.heightAnchor.constraint(equalToConstant: 40),
            changeEmailButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            changeEmailButton.topAnchor.constraint(equalTo: resendEmailButton.bottomAnchor, constant: 16),
        ])
        
        titleLabel.text = "Confirm your email address"
        messageLabel.text = "We sent a confirmation email to you. Please check your inbox and open the link"
//        if let emailAddress = verificationSession.emailAddress {
//            messageLabel.attributedText = "We sent a confirmation email to "
//            + "\(emailAddress)"
//                .font(size: 16, weight: .bold)
//            + ". Please check your inbox and open the link"
//        }
        
        emailField.placeholder = "Email address"
        emailField.textAlignment = .center
        emailField.keyboardType = .emailAddress
        emailField.text = verificationSession.emailAddress
        emailField.returnKeyType = .done
        emailField.isEnabled = false
        emailField.alpha = 0.7
        
        notReceivingEmailLabel.text = "Not receiving email?"
        
        resendEmailButton.setTitle("Resend email", for: .normal)
        resendEmailButton.addTarget(self, action: #selector(resendEmailTap(_:)), for: .touchUpInside)
        
        changeEmailButton.setTitle("Change email address", for: .normal)
        changeEmailButton.addTarget(self, action: #selector(changeEmailTap(_:)), for: .touchUpInside)
        
        activityIndicator.startAnimating()
        
//        Task {
//            try await verificationSession.resumeOnEmailConfirmed()
//            
//            switch verificationSession.verificationStatus {
//            case .verified:
//                if verificationSession.hasMembership {
//                    Page.currentPage.send(.selectNFTImage(walletSession: walletSession, verificationSession: verificationSession, membershipDuration: 0))
//                } else {
//                    Page.currentPage.send(.selectMembership(walletSession: walletSession, verificationSession: verificationSession))
//                }
//            case .processing:
//                Page.currentPage.send(.personaCompletePage(walletSession: walletSession, verificationSession: verificationSession))
//            case .notVerified:
//                Page.currentPage.send(.personaVerification(walletSession: walletSession, verificationSession: verificationSession))
//            }
//        }
    }
    
    @objc func resendEmailTap(_ sender: Any) {
        Task {
            try await verificationSession.resendConfirmationEmail()
        }
    }
    
    @objc func changeEmailTap(_ sender: Any) {
        emailField.isEnabled = true
        emailField.alpha = 1
        emailField.becomeFirstResponder()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        emailChangeSuccessSign.isHidden = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        guard let text = textField.text,
              !text.isEmpty
        else {
            return false
        }
        
        Task {
            do {
                try await verificationSession.updateEmail(text)
                emailChangeSuccessSign.image = UIImage(systemName: "checkmark.circle")
                emailChangeSuccessSign.tintColor = .systemGreen
            } catch let error {
                print(error)
                emailChangeSuccessSign.image = UIImage(systemName: "exclamationmark.octagon.fill")
                emailChangeSuccessSign.tintColor = .systemRed
            }
            emailChangeSuccessSign.isHidden = false
            textField.alpha = 0.7
            textField.resignFirstResponder()
            textField.isEnabled = false
        }
        
        return true
    }
}
