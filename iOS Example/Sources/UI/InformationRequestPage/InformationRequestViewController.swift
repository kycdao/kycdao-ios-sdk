//
//  InformationRequestViewController.swift
//  
//
//  Created by Vekety Robin on 2022. 07. 08..
//

import Foundation
import UIKit
import Combine
import KycDao
import SafariServices

struct Country {
    let isoCode: String
    let name: String
}

// By starting the verification you accept Privacy Policy and Terms & Conditions.

class InformationRequestViewController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    private var disposeBag = Set<AnyCancellable>()
    private let privacyPolicy = "Privacy Policy"
    private let tos = "Terms & Conditions"
    
    private var walletSession: WalletConnectSession
    private var verificationSession: VerificationSession
    
    private var countries: [Country]
    private var selectedCountry: Country? {
        didSet {
            checkCompletion()
        }
    }
    
    private var emailAddress: String? {
        didSet {
            checkCompletion()
        }
    }
    
    let emailField = UITextField()
    let emailSeparator = UIView()
    let residencyField = UITextField()
    let residencySeparator = UIView()
    let legalEntityStatusCheck = UIButton()
    let disclaimerTitle = UILabel()
    let disclaimerText = UITextView()
    let tosAndPpText = UILabel()
    let disclaimerAcceptance = UIButton()
    let continueButton = SimpleButton()
    
    init(walletSession: WalletConnectSession, verificationSession: VerificationSession) {
        
        self.walletSession = walletSession
        self.verificationSession = verificationSession
        
        self.countries = Locale.isoRegionCodes.compactMap { regionCode -> Country? in
            guard let name = Locale.current.localizedString(forRegionCode: regionCode) else {
                return nil
            }
            
            return Country(isoCode: regionCode, name: name)
        }.sorted { lhs, rhs in
            lhs.name < rhs.name
        }
        
        super.init(nibName: nil, bundle: nil)
        
        legalEntityStatusCheck.isEnabled = false
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        residencyField.inputView = pickerView
        
        emailField.publisher(for: \.text).sink { text in
            self.emailAddress = text
        }.store(in: &disposeBag)
        
//        legalEntityStatusCheck.isSelected = verificationSession.legalEntityStatus
        disclaimerAcceptance.isSelected = verificationSession.disclaimerAccepted
//        emailField.text = verificationSession.emailAddress
        
//        selectedCountry = countries.first { $0.isoCode == verificationSession.residency }
        residencyField.text = selectedCountry?.name
        
//        guard let selectedIndex = countries.firstIndex(where: { $0.isoCode == verificationSession.residency })
//        else {
//            return
//        }
//
//        pickerView.selectRow(selectedIndex, inComponent: 0, animated: false)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        
        title = "Personal Information"
        
        view.backgroundColor = .systemBackground
        
        emailSeparator.backgroundColor = .systemGray5
        residencySeparator.backgroundColor = .systemGray5
        
        legalEntityStatusCheck.setTitleColor(.secondaryLabel, for: .normal)
        legalEntityStatusCheck.titleLabel?.font = .systemFont(ofSize: 15)
        
        disclaimerTitle.font = .systemFont(ofSize: 18, weight: .semibold)
        disclaimerTitle.textAlignment = .center
        
        disclaimerText.font = .systemFont(ofSize: 13)
        
        tosAndPpText.font = .systemFont(ofSize: 15)
        tosAndPpText.numberOfLines = 0
        tosAndPpText.lineBreakMode = .byWordWrapping
        
        let iconSizeConfig = UIImage.SymbolConfiguration(pointSize: 24)
        
        let notSelectedImage = UIImage(systemName: "circle",
                                       withConfiguration: iconSizeConfig)?
            .withAlignmentRectInsets(.init(top: 0, left: 0, bottom: 0, right: 10))
        
        let selectedImage = UIImage(systemName: "checkmark.circle.fill",
                                    withConfiguration: iconSizeConfig)
        
        legalEntityStatusCheck.setImage(notSelectedImage, for: .normal)
        
        legalEntityStatusCheck.setImage(selectedImage, for: .selected)
        
        disclaimerAcceptance.setTitleColor(.secondaryLabel, for: .normal)
        disclaimerAcceptance.titleLabel?.font = .systemFont(ofSize: 15)
        disclaimerAcceptance.setImage(notSelectedImage, for: .normal)
        disclaimerAcceptance.setImage(selectedImage, for: .selected)
        
        view.addSubview(emailField)
        view.addSubview(emailSeparator)
        view.addSubview(residencyField)
        view.addSubview(residencySeparator)
        view.addSubview(legalEntityStatusCheck)
        view.addSubview(disclaimerTitle)
        view.addSubview(disclaimerText)
        view.addSubview(tosAndPpText)
        view.addSubview(disclaimerAcceptance)
        view.addSubview(continueButton)
        
        emailField.translatesAutoresizingMaskIntoConstraints = false
        emailSeparator.translatesAutoresizingMaskIntoConstraints = false
        residencyField.translatesAutoresizingMaskIntoConstraints = false
        residencySeparator.translatesAutoresizingMaskIntoConstraints = false
        legalEntityStatusCheck.translatesAutoresizingMaskIntoConstraints = false
        disclaimerTitle.translatesAutoresizingMaskIntoConstraints = false
        disclaimerText.translatesAutoresizingMaskIntoConstraints = false
        tosAndPpText.translatesAutoresizingMaskIntoConstraints = false
        disclaimerAcceptance.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            emailField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emailField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            emailField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            
            emailSeparator.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32),
            emailSeparator.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 4),
            emailSeparator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emailSeparator.heightAnchor.constraint(equalToConstant: 1),
            
            residencyField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            residencyField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            residencyField.topAnchor.constraint(equalTo: emailSeparator.bottomAnchor, constant: 16),
            
            residencySeparator.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32),
            residencySeparator.topAnchor.constraint(equalTo: residencyField.bottomAnchor, constant: 4),
            residencySeparator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            residencySeparator.heightAnchor.constraint(equalToConstant: 1),
            
            legalEntityStatusCheck.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            legalEntityStatusCheck.topAnchor.constraint(equalTo: residencySeparator.bottomAnchor, constant: 26),
            
            disclaimerTitle.topAnchor.constraint(equalTo: legalEntityStatusCheck.bottomAnchor, constant: 16),
            disclaimerTitle.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            disclaimerTitle.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            disclaimerTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            disclaimerText.topAnchor.constraint(equalTo: disclaimerTitle.bottomAnchor, constant: 4),
            disclaimerText.bottomAnchor.constraint(equalTo: tosAndPpText.topAnchor, constant: -16),
            disclaimerText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            disclaimerText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            
            tosAndPpText.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tosAndPpText.bottomAnchor.constraint(equalTo: disclaimerAcceptance.topAnchor, constant: -16),
            tosAndPpText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tosAndPpText.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            disclaimerAcceptance.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            disclaimerAcceptance.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -16),
            
            continueButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            continueButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.heightAnchor.constraint(equalToConstant: 40),
            continueButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            continueButton.topAnchor.constraint(greaterThanOrEqualTo: disclaimerAcceptance.bottomAnchor, constant: 20)
        ])
        
        emailField.placeholder = "Email address"
        emailField.keyboardType = .emailAddress
        
        residencyField.placeholder = "Residency"
        legalEntityStatusCheck.setTitle("  User is legal entity (e.g. a business)", for: .normal)
        disclaimerAcceptance.setTitle("  Accept disclaimer", for: .normal)
        
        continueButton.setTitle("Continue", for: .normal)
        
        legalEntityStatusCheck.addTarget(self, action: #selector(legalEntityCheckTap(_:)), for: .touchUpInside)
        disclaimerAcceptance.addTarget(self, action: #selector(disclaimerAcceptanceTap(_:)), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(continueTap(_:)), for: .touchUpInside)
        
        let text = "By starting the verification you accept \(privacyPolicy) and \(tos)."
        let privacyPolicyRange = (text as NSString).range(of: privacyPolicy)
        let tosRange = (text as NSString).range(of: tos)
        let attributedString = NSMutableAttributedString(attributedString: NSAttributedString(string: text))
        attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: privacyPolicyRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: tosRange)
        
        tosAndPpText.attributedText = attributedString
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ppOrTosTap))
        tosAndPpText.addGestureRecognizer(tapGesture)
        tosAndPpText.isUserInteractionEnabled = true
        
        disclaimerTitle.text = "Disclaimer"
        disclaimerText.text = verificationSession.disclaimerText
        
    }
    
    @objc func legalEntityCheckTap(_ sender: Any) {
        legalEntityStatusCheck.isSelected.toggle()
    }
    
    @objc func disclaimerAcceptanceTap(_ sender: Any) {
        disclaimerAcceptance.isSelected.toggle()
        checkCompletion()
    }
    
    @objc func continueTap(_ sender: Any) {
        guard let emailAddress = emailAddress,
              let residency = selectedCountry?.isoCode else {
            return
        }
        
        Task {
            
            try await verificationSession.acceptDisclaimer()
//            try await verificationSession.savePersonalInfo(email: emailAddress,
//                                                  residency: residency,
//                                                  legalEntity: legalEntityStatusCheck.isSelected)
            
            try await verificationSession.setPersonalData(PersonalData(email: emailAddress,
                                                                       residency: residency))
            
            Page.currentPage.send(.confirmEmail(walletSession: walletSession, verificationSession: verificationSession))
            
        }
        
    }
    
    @objc func ppOrTosTap(gesture: UITapGestureRecognizer) {
            
            if gesture.didTapAttributedString(privacyPolicy, in: tosAndPpText) {
                
                let safariVC = SFSafariViewController(url: verificationSession.privacyPolicy)
                safariVC.modalPresentationStyle = .currentContext
                self.present(safariVC, animated: true)
                
            } else if gesture.didTapAttributedString(tos, in: tosAndPpText) {
                
                let safariVC = SFSafariViewController(url: verificationSession.termsOfService)
                safariVC.modalPresentationStyle = .currentContext
                self.present(safariVC, animated: true)
                
            }
        }
    
    func checkCompletion() {
        
        var emailFieldValid = false
        
        if let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue), let emailAddress = emailAddress {
            let range = NSMakeRange(0, emailAddress.count)
            let allMatches = dataDetector.matches(in: emailAddress,
                                                  options: [],
                                                  range: range)

            if allMatches.count == 1, allMatches.first?.url?.absoluteString.contains("mailto:") == true {
                emailFieldValid = true
            }
        }
        
        continueButton.isEnabled = emailFieldValid && selectedCountry != nil && disclaimerAcceptance.isSelected
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        countries.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        countries[safe: row]?.name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCountry = countries[safe: row]
        residencyField.text = selectedCountry?.name
    }
    
    public func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view?.isKind(of: UIButton.self) ?? false {
            return false
        }
        return true
    }

    public func gestureRecognizer(_: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isKind(of: UIControl.self) ?? false {
            return false
        }

        return true
    }
    
}
