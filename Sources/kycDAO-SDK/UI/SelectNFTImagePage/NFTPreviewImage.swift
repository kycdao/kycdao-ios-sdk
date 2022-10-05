//
//  NFTPreviewImage.swift
//  
//
//  Created by Vekety Robin on 2022. 08. 23..
//

import Foundation
import UIKit
import WebKit

class NFTPreviewImage: UIView {
    
    let svgWebView = WKWebView()
    
    init() {
        
        super.init(frame: .zero)
        addSubview(svgWebView)
        
        svgWebView.translatesAutoresizingMaskIntoConstraints = false
        svgWebView.scrollView.isScrollEnabled = false
        
        backgroundColor = .white
        
        layer.cornerRadius = 12
        
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        
        let nftImageSpacingQuarter = (UIScreen.main.bounds.width - UIScreen.main.bounds.width * 0.8) / 4
        
        NSLayoutConstraint.activate([
            svgWebView.topAnchor.constraint(equalTo: self.topAnchor, constant: nftImageSpacingQuarter),
            svgWebView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -nftImageSpacingQuarter),
            svgWebView.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor),
            svgWebView.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor),
            svgWebView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            svgWebView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.7),
            svgWebView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.7)
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImageURL(imageURL: URL?) {
        
        guard let imageURL = imageURL else {
            return
        }

        svgWebView.load(URLRequest(url: imageURL))
        
    }
    
}
