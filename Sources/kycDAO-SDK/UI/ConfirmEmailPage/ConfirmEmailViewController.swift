//
//  ConfirmEmailViewController.swift
//  
//
//  Created by Vekety Robin on 2022. 07. 08..
//

import Foundation
import UIKit

class ConfirmEmailViewController : UIViewController {
    
    private var walletSession: WalletConnectSession
    private var verificationSession: VerificationSession
    
    let containerView = UIView()
    let titleLabel = UILabel()
    let messageLabel = UILabel()
    let activityIndicator = UIActivityIndicatorView()
    
    let notReceivingEmailLabel = UILabel()
    let resendEmailButton = SimpleButton(style: .outline)
    
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
        
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(activityIndicator)
        
        view.addSubview(notReceivingEmailLabel)
        view.addSubview(resendEmailButton)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        resendEmailButton.translatesAutoresizingMaskIntoConstraints = false
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
            
            activityIndicator.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            activityIndicator.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            activityIndicator.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            resendEmailButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            resendEmailButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            resendEmailButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            resendEmailButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resendEmailButton.heightAnchor.constraint(equalToConstant: 40),
            resendEmailButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            resendEmailButton.topAnchor.constraint(greaterThanOrEqualTo: containerView.bottomAnchor, constant: 20),
            
            notReceivingEmailLabel.bottomAnchor.constraint(equalTo: resendEmailButton.topAnchor, constant: -12),
            notReceivingEmailLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            notReceivingEmailLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: 16),
            notReceivingEmailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        titleLabel.text = "Confirm your email address"
        messageLabel.text = "We sent a confirmation email to you. Please check your inbox and open the link"
//        if let emailAddress = verificationSession.emailAddress {
//            messageLabel.attributedText = "We sent a confirmation email to "
//            + "\(emailAddress)"
//                .font(size: 16, weight: .bold)
//            + ". Please check your inbox and open the link"
//        }
        
        notReceivingEmailLabel.text = "Not receiving email?"
        
        resendEmailButton.setTitle("Resend email", for: .normal)
        
        resendEmailButton.addTarget(self, action: #selector(resendEmailTap(_:)), for: .touchUpInside)
        
        activityIndicator.startAnimating()
        
        Task {
            try await verificationSession.resumeOnEmailConfirmed()
            
            switch verificationSession.verificationStatus {
            case .verified:
                Page.currentPage.send(.selectNFTImage(walletSession: walletSession, verificationSession: verificationSession))
            case .processing:
                Page.currentPage.send(.personaCompletePage(walletSession: walletSession, verificationSession: verificationSession))
            case .notVerified:
                Page.currentPage.send(.personaVerification(walletSession: walletSession, verificationSession: verificationSession))
            }
        }
    }
    
    @objc func resendEmailTap(_ sender: Any) {
        Task {
            try await verificationSession.sendConfirmationEmail()
        }
    }
}


protocol NSAttributedStringValueType { }
extension UIColor : NSAttributedStringValueType { }
extension UIFont : NSAttributedStringValueType { }

extension NSMutableAttributedString {
    
    func addAttributes(_ attrs: [NSAttributedString.Key: NSAttributedStringValueType]) {
        addAttributes(attrs, range: NSRange(location: 0, length: string.count))
    }
    
    static func +(lhs: NSMutableAttributedString, rhs: NSAttributedString) -> NSMutableAttributedString {
        
        lhs.append(rhs)
        
        return lhs
    }
    
    static func +(lhs: String, rhs: NSMutableAttributedString) -> NSMutableAttributedString {
        
        let attributedString = NSMutableAttributedString(string: lhs)
        attributedString.append(rhs)
        
        return attributedString
    }
    
    static func +(lhs: NSMutableAttributedString, rhs: String) -> NSMutableAttributedString {
        
        let attributedString = NSMutableAttributedString(string: rhs)
        lhs.append(attributedString)
        
        return lhs
    }
    
}

extension String {
    
    func font(size: CGFloat, weight: UIFont.Weight) -> NSMutableAttributedString {
        
        let attrString = NSMutableAttributedString(string: self)
        
        attrString.addAttributes([
            .font : UIFont.systemFont(ofSize: size, weight: weight)
        ])
        
        return attrString
    }
    
    func font(_ font: UIFont) -> NSMutableAttributedString {
        
        let attrString = NSMutableAttributedString(string: self)
        
        attrString.addAttributes([
            .font : font
        ])
        
        return attrString
        
    }
    
    func textColor(_ color: UIColor) -> NSMutableAttributedString {
        
        let attrString = NSMutableAttributedString(string: self)
        
        attrString.addAttributes([
            .foregroundColor: color
        ])
        
        return attrString
        
    }
    
}

