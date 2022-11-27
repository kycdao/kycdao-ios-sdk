//
//  MainViewController.swift
//  iOS Example
//
//  Created by Vekety Robin on 2022. 06. 17..
//

import Foundation
import UIKit
import KycDao
import Combine

class MainViewController: UIViewController, UITextFieldDelegate {
    
    private var disposeBag = Set<AnyCancellable>()
    
    let kycSectionLabel = UILabel()
    let kycFlowSeparator = UIView()
    
    let startDemo = SimpleButton()
    
    let addressTokenCheckSectionLabel = UILabel()
    let addressTokenCheckSeparator = UIView()
    
    let walletAddressField = UITextField()
    let hasValidToken = SimpleButton()
    let hasValidTokenLabel = UILabel()
    
    let connectWalletSectionLabel = UILabel()
    let connectWalletSeparator = UIView()
    
    let connectWallet = SimpleButton()
    let connectedWalletAddress = UILabel()
    let hasValidToken2 = SimpleButton()
    let hasValidTokenLabel2 = UILabel()
    
    //@Published
    var latestWalletSession: WalletConnectSession? {
        didSet {
            guard let address = latestWalletSession?.accounts.first else { return }
            connectedWalletAddress.text = "\(address)"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        view.addSubview(kycSectionLabel)
        view.addSubview(kycFlowSeparator)
        view.addSubview(startDemo)
        view.addSubview(addressTokenCheckSectionLabel)
        view.addSubview(addressTokenCheckSeparator)
        view.addSubview(walletAddressField)
        view.addSubview(hasValidToken)
        view.addSubview(hasValidTokenLabel)
        view.addSubview(connectWalletSectionLabel)
        view.addSubview(connectWalletSeparator)
        view.addSubview(connectWallet)
        view.addSubview(connectedWalletAddress)
        view.addSubview(hasValidToken2)
        view.addSubview(hasValidTokenLabel2)
        
        kycSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        kycFlowSeparator.backgroundColor = .systemGray5
        kycFlowSeparator.translatesAutoresizingMaskIntoConstraints = false
        
        startDemo.translatesAutoresizingMaskIntoConstraints = false
        
        addressTokenCheckSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addressTokenCheckSeparator.backgroundColor = .systemGray5
        addressTokenCheckSeparator.translatesAutoresizingMaskIntoConstraints = false
        
        walletAddressField.translatesAutoresizingMaskIntoConstraints = false
        
        hasValidToken.translatesAutoresizingMaskIntoConstraints = false
        
        hasValidTokenLabel.translatesAutoresizingMaskIntoConstraints = false
        
        connectWalletSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        connectWalletSeparator.backgroundColor = .systemGray5
        connectWalletSeparator.translatesAutoresizingMaskIntoConstraints = false
        
        connectWallet.translatesAutoresizingMaskIntoConstraints = false
        
        connectedWalletAddress.translatesAutoresizingMaskIntoConstraints = false
        
        hasValidToken2.translatesAutoresizingMaskIntoConstraints = false
        
        hasValidTokenLabel2.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            kycSectionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            kycSectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            kycSectionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            
            kycFlowSeparator.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32),
            kycFlowSeparator.topAnchor.constraint(equalTo: kycSectionLabel.bottomAnchor, constant: 4),
            kycFlowSeparator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            kycFlowSeparator.heightAnchor.constraint(equalToConstant: 1),
            
            startDemo.topAnchor.constraint(equalTo: kycFlowSeparator.topAnchor, constant: 20),
            startDemo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startDemo.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            startDemo.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            startDemo.heightAnchor.constraint(equalToConstant: 40),
            startDemo.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            
            addressTokenCheckSectionLabel.topAnchor.constraint(equalTo: startDemo.bottomAnchor, constant: 32),
            addressTokenCheckSectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addressTokenCheckSectionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            
            addressTokenCheckSeparator.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32),
            addressTokenCheckSeparator.topAnchor.constraint(equalTo: addressTokenCheckSectionLabel.bottomAnchor, constant: 4),
            addressTokenCheckSeparator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addressTokenCheckSeparator.heightAnchor.constraint(equalToConstant: 1),
            
            walletAddressField.topAnchor.constraint(equalTo: addressTokenCheckSeparator.bottomAnchor, constant: 20),
            walletAddressField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            walletAddressField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            hasValidToken.topAnchor.constraint(equalTo: walletAddressField.bottomAnchor, constant: 20),
            hasValidToken.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hasValidToken.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            hasValidToken.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            hasValidToken.heightAnchor.constraint(equalToConstant: 40),
            hasValidToken.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            
            hasValidTokenLabel.topAnchor.constraint(equalTo: hasValidToken.bottomAnchor, constant: 20),
            hasValidTokenLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hasValidTokenLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            hasValidTokenLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            
            connectWalletSectionLabel.topAnchor.constraint(equalTo: hasValidTokenLabel.bottomAnchor, constant: 32),
            connectWalletSectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            connectWalletSectionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            
            connectWalletSeparator.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32),
            connectWalletSeparator.topAnchor.constraint(equalTo: connectWalletSectionLabel.bottomAnchor, constant: 4),
            connectWalletSeparator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectWalletSeparator.heightAnchor.constraint(equalToConstant: 1),
            
            connectWallet.topAnchor.constraint(equalTo: connectWalletSeparator.bottomAnchor, constant: 20),
            connectWallet.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectWallet.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            connectWallet.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            connectWallet.heightAnchor.constraint(equalToConstant: 40),
            connectWallet.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            
            connectedWalletAddress.topAnchor.constraint(equalTo: connectWallet.bottomAnchor, constant: 20),
            connectedWalletAddress.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectedWalletAddress.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            connectedWalletAddress.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            
            hasValidToken2.topAnchor.constraint(equalTo: connectedWalletAddress.bottomAnchor, constant: 20),
            hasValidToken2.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hasValidToken2.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            hasValidToken2.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            hasValidToken2.heightAnchor.constraint(equalToConstant: 40),
            hasValidToken2.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            
            hasValidTokenLabel2.topAnchor.constraint(equalTo: hasValidToken2.bottomAnchor, constant: 20),
            hasValidTokenLabel2.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hasValidTokenLabel2.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            hasValidTokenLabel2.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
        ])
        
        kycSectionLabel.text = "KYC flow"
        kycSectionLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        
        startDemo.setTitle("Start KYC Flow", for: .normal)
        startDemo.addTarget(self, action: #selector(startDemo(_:)), for: .touchUpInside)
        
        addressTokenCheckSectionLabel.text = "Check token for address"
        addressTokenCheckSectionLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        
        walletAddressField.placeholder = "Polygon Wallet Address"
        walletAddressField.delegate = self
        walletAddressField.returnKeyType = .done
        
        hasValidToken.setTitle("Address has valid token?", for: .normal)
        hasValidToken.addTarget(self, action: #selector(hasValidToken(_:)), for: .touchUpInside)
        
        hasValidTokenLabel.text = "Enter a polygon address to check token"
        
        connectWalletSectionLabel.text = "Check token for connected wallet"
        connectWalletSectionLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        
        connectWallet.setTitle("Connect MetaMask Wallet", for: .normal)
        connectWallet.addTarget(self, action: #selector(connectWallet(_:)), for: .touchUpInside)
        
        connectedWalletAddress.text = "No wallet connected"
        connectedWalletAddress.textAlignment = .center
        connectedWalletAddress.lineBreakMode = .byCharWrapping
        connectedWalletAddress.numberOfLines = 0
        connectedWalletAddress.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        connectedWalletAddress.textColor = .systemGray
        
        hasValidToken2.setTitle("Wallet has valid token?", for: .normal)
        hasValidToken2.addTarget(self, action: #selector(hasValidTokenWC(_:)), for: .touchUpInside)
        
        hasValidTokenLabel2.text = "Connect a wallet to check token"
        
        WalletConnectManager.shared.startListening()
        WalletConnectManager.shared.sessionStarted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] walletSession in
                self?.latestWalletSession = walletSession
            }.store(in: &disposeBag)
    }
    
    @objc func startDemo(_ sender: Any) {
        let kycVC = KycDaoViewController()
        //kycVC.modalPresentationStyle = .fullScreen
        present(kycVC, animated: true)
    }
    
    @objc func hasValidToken(_ sender: Any) {
        guard let address = walletAddressField.text, !address.isEmpty else {
            blinkView(hasValidTokenLabel)
            return
        }
        Task {
            let hasValidToken = try await VerificationManager.shared.hasValidToken(verificationType: .kyc,
                                                                          walletAddress: address,
                                                                          chainId: "eip155:80001")
            hasValidTokenLabel.text = hasValidToken ? "Wallet has a valid KYC token" : "Wallet does NOT have a valid KYC token"
            print("hasValidToken: \(hasValidToken)")
        }
    }
    
    @objc func connectWallet(_ sender: Any) {
        Task {
            let wallets = try await WalletConnectManager.listWallets()
            //find metamask
            guard let metamask = wallets.first(where: { $0.name.lowercased() == "metamask" }) else {
                return
            }
            try WalletConnectManager.shared.connect(withWallet: metamask)
        }
    }
    
    @objc func hasValidTokenWC(_ sender: Any) {
        guard let walletSession = latestWalletSession,
              let firstAccount = walletSession.accounts.first else {
            blinkView(hasValidTokenLabel2)
            return
        }
        Task {
            let hasValidToken = try await VerificationManager.shared.hasValidToken(verificationType: .kyc,
                                                                          walletAddress: firstAccount,
                                                                          walletSession: walletSession)
            hasValidTokenLabel2.text = hasValidToken ? "Wallet has a valid KYC token" : "Wallet does NOT have a valid KYC token"
            print("hasValidToken: \(hasValidToken)")
        }
    }
    
    func blinkView(_ view: UIView) {
        UIView.animate(withDuration: 0.2, animations: {
            view.alpha = 0.5
        }, completion: { _ in
            UIView.animate(withDuration: 0.2,
                           delay:0.0,
                           options:[.allowUserInteraction, .curveEaseInOut],
                           animations: {
                UIView.modifyAnimations(withRepeatCount: 1, autoreverses: true) {
                    view.alpha = 1
                }
            })
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
    }
    
}


class SimpleButton: UIButton {
    
    enum Style {
        case filled
        case outline
    }
    
    override var isEnabled: Bool {
        didSet {
            updateLooks()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.9 : 1.0
        }
    }
    
    var color: UIColor = .systemBlue {
        didSet {
            updateLooks()
        }
    }
    
    private var style: Style
    
    init(style: Style = .filled) {
        self.style = style
        super.init(frame: .zero)
        
        titleLabel?.font = .systemFont(ofSize: 20)

        clipsToBounds = true
        layer.cornerRadius = 20
        
        updateLooks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateLooks() {
        switch style {
        case .filled:
            backgroundColor = isEnabled ? color : .systemGray3
            layer.borderWidth = 0
            
            setTitleColor(.white, for: .normal)
            setTitleColor(.systemGray, for: .disabled)
            
        case .outline:
            backgroundColor = .systemBackground
            layer.borderColor = isEnabled ? color.cgColor : UIColor.systemGray3.cgColor
            layer.borderWidth = 1.0
            
            setTitleColor(color, for: .normal)
            setTitleColor(color, for: .disabled)
        }
    }
}
