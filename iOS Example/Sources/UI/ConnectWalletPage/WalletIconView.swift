//
//  WalletIconView.swift
//  
//
//  Created by Vekety Robin on 2022. 06. 20..
//

import Foundation
import UIKit

class WalletIconView : UIImageView {
    override var image: UIImage? {
        didSet {
            if let image = image {
                backgroundColor = nil
            } else {
                backgroundColor = .systemGray
            }
        }
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemGray
        contentMode = .scaleAspectFit
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.width / 4
    }
}
