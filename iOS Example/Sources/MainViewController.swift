//
//  MainViewController.swift
//  iOS Example
//
//  Created by Vekety Robin on 2022. 06. 17..
//

import Foundation
import UIKit
import KycDao

class MainViewController: UIViewController {
    
    var startDemo = UIButton()
    
    var hasValidToken = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        view.addSubview(startDemo)
        view.addSubview(hasValidToken)
        
        startDemo.setTitleColor(.label, for: .normal)
        startDemo.translatesAutoresizingMaskIntoConstraints = false
        
        hasValidToken.setTitleColor(.label, for: .normal)
        hasValidToken.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            startDemo.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            startDemo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startDemo.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            startDemo.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            
            hasValidToken.topAnchor.constraint(equalTo: startDemo.bottomAnchor, constant: 20),
            hasValidToken.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hasValidToken.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            hasValidToken.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
        ])
        
        startDemo.setTitle("Start KYC Flow", for: .normal)
        
        startDemo.addTarget(self, action: #selector(startDemo(_:)), for: .touchUpInside)
        
        hasValidToken.setTitle("Has valid token?", for: .normal)
        hasValidToken.addTarget(self, action: #selector(hasValidToken(_:)), for: .touchUpInside)
    }
    
    @objc func startDemo(_ sender: Any) {
        let kycVC = KycDaoViewController()
        //kycVC.modalPresentationStyle = .fullScreen
        present(kycVC, animated: true)
    }
    
    @objc func hasValidToken(_ sender: Any) {
        Task {
            let hasValidToken = try await KYCManager.shared.hasValidToken(verificationType: .kyc,
                                                                          walletAddress: "0x25504d2df90d1b4BC1f6A823efF88a6aB4c8EA91",
                                                                          networkOptions: NetworkOptions(chainId: "eip155:80001"))
            print("hasValidToken: \(hasValidToken)")
        }
    }
    
}
