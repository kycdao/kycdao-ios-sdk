//
//  WalletCell.swift
//  
//
//  Created by Vekety Robin on 2022. 06. 20..
//

import Foundation
import UIKit

class WalletCell: UICollectionViewCell {
    
    let containerView = UIView()
    private let walletIcon = WalletIconView()
    let walletLabel: UILabel = {
        let walletLabel = UILabel()
        walletLabel.font = .systemFont(ofSize: 12)
        walletLabel.textAlignment = .center
        return walletLabel
    }()
    
    var imageURL: URL? {
        didSet {
            guard let imageURL = imageURL else {
                return
            }

            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: imageURL)
                    walletIcon.image = UIImage(data: data)
                } catch {
                    print("Failed to download icon")
                }
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(containerView)
        containerView.addSubview(walletIcon)
        containerView.addSubview(walletLabel)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        walletIcon.translatesAutoresizingMaskIntoConstraints = false
        walletLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            containerView.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            
            walletIcon.topAnchor.constraint(equalTo: containerView.topAnchor),
            walletIcon.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            walletIcon.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.7),
            walletIcon.heightAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.7),
            
            walletLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            walletLabel.topAnchor.constraint(equalTo: walletIcon.bottomAnchor, constant: 6),
            walletLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor),
            walletLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            walletLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            walletLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.85)
        ])
        
        //https://imagedelivery.net/_aTEfDRm7z3tKgu9JhfeKA/a03bfa44-ce98-4883-9b2a-75e2b68f5700/sm
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
