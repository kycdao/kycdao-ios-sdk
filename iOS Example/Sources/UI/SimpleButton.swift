//
//  SimpleButton.swift
//  iOS Example
//
//  Created by Vekety Robin on 2022. 12. 07..
//

import Foundation
import UIKit

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
