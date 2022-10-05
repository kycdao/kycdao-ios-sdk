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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        view.addSubview(startDemo)
        
        startDemo.setTitleColor(.label, for: .normal)
        
        startDemo.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            startDemo.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            startDemo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startDemo.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            startDemo.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor)
        ])
        
        startDemo.setTitle("Start KYC Flow", for: .normal)
        
        startDemo.addTarget(self, action: #selector(startDemo(_:)), for: .touchUpInside)
    }
    
    @objc func startDemo(_ sender: Any) {
        let kycVC = KycDaoViewController()
        //kycVC.modalPresentationStyle = .fullScreen
        present(kycVC, animated: true)
    }
    
}
