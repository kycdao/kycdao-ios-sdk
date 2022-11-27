//
//  MintNFTViewController.swift
//  
//
//  Created by Vekety Robin on 2022. 07. 26..
//

import Foundation
import UIKit
import WebKit
import WalletConnectSwift
import web3

class MintNFTViewController: UIViewController {
    
    let containerView = UIView()
    let imageTitle = UILabel()
    let svgWebView = WKWebView()
    let mintingFeeTitle = UILabel()
    let mintingFee = UILabel()
    let mintNFTButton = SimpleButton()
    
    private var walletSession: WalletConnectSession
    private var verificationSession: VerificationSession
    private let selectedImage: TokenImage
    
    init(walletSession: WalletConnectSession, verificationSession: VerificationSession, selectedImage: TokenImage) {
        self.walletSession = walletSession
        self.verificationSession = verificationSession
        self.selectedImage = selectedImage
        super.init(nibName: nil, bundle: nil)
        
        if let imageUrl = selectedImage.url {
            svgWebView.load(URLRequest(url: imageUrl))
        }
        
        Task {
            do {
                let gasEstimation = try await verificationSession.estimateGasForMinting()
                mintingFee.text = gasEstimation.feeInNative
            } catch let error {
                print(error)
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        imageTitle.font = .systemFont(ofSize: 20, weight: .semibold)
        mintingFeeTitle.font = .systemFont(ofSize: 16)
        mintingFee.font = .systemFont(ofSize: 18, weight: .semibold)
        
        view.addSubview(containerView)
        containerView.addSubview(imageTitle)
        containerView.addSubview(svgWebView)
        containerView.addSubview(mintingFeeTitle)
        containerView.addSubview(mintingFee)
        containerView.addSubview(mintNFTButton)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        svgWebView.translatesAutoresizingMaskIntoConstraints = false
        imageTitle.translatesAutoresizingMaskIntoConstraints = false
        mintingFeeTitle.translatesAutoresizingMaskIntoConstraints = false
        mintingFee.translatesAutoresizingMaskIntoConstraints = false
        mintNFTButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            containerView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            imageTitle.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageTitle.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageTitle.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            imageTitle.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            
            svgWebView.topAnchor.constraint(equalTo: imageTitle.bottomAnchor, constant: 32),
            svgWebView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            svgWebView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            svgWebView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            
            mintingFeeTitle.topAnchor.constraint(equalTo: svgWebView.bottomAnchor, constant: 32),
            mintingFeeTitle.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            mintingFeeTitle.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            mintingFeeTitle.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            
            mintingFee.topAnchor.constraint(equalTo: mintingFeeTitle.bottomAnchor, constant: 4),
            mintingFee.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            mintingFee.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            mintingFee.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            
            mintNFTButton.topAnchor.constraint(equalTo: mintingFee.bottomAnchor, constant: 24),
            mintNFTButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            mintNFTButton.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            mintNFTButton.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            mintNFTButton.heightAnchor.constraint(equalToConstant: 40),
            mintNFTButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            mintNFTButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        
        imageTitle.text = "Your kycDAO NFT"
        
        mintingFeeTitle.text = "Minting fee:"
        
        mintNFTButton.setTitle("Mint NFT", for: .normal)
        mintNFTButton.addTarget(self, action: #selector(mintNFTTap(_:)), for: .touchUpInside)
        
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)), for: .normal)
        backButton.setTitle("Back", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 18)
        backButton.addTarget(self, action: #selector(backAction(sender:)), for: .touchUpInside)
        backButton.setInsets(forContentPadding: .init(top: 0, left: -6, bottom: 0, right: 0), imageTitlePadding: 4)
        
        let customBackButton = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = customBackButton
        
    }
    
    @objc func backAction(sender: UIBarButtonItem) {
        if let nftSelectionController = navigationController?.viewControllers.first(where: { $0 is SelectNFTImageViewController }) as? SelectNFTImageViewController {
            self.navigationController?.popToViewController(nftSelectionController, animated: true)
        }
    }
    
    @objc func mintNFTTap(_ sender: Any) {
        
        Page.currentPage.send(.mintingInProgress(walletSession: walletSession, verificationSession: verificationSession))
        
    }
    
}
