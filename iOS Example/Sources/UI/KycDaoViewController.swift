//
//  KycDaoViewController.swift
//  
//
//  Created by Vekety Robin on 2022. 06. 17..
//

import Foundation
import UIKit
import Combine
import KycDao

enum Page {
    static let currentPage = CurrentValueSubject<Page, Never>(.walletSelector())
    
    case walletSelector(animated: Bool = false)
    case accountSelector(accounts: [String], walletSession: WalletConnectSession)
    case createSignature(walletSession: WalletConnectSession, verificationSession: VerificationSession)
    case informationRequest(walletSession: WalletConnectSession, verificationSession: VerificationSession)
    case confirmEmail(walletSession: WalletConnectSession, verificationSession: VerificationSession)
    case personaVerification(walletSession: WalletConnectSession, verificationSession: VerificationSession)
    case personaCompletePage(walletSession: WalletConnectSession, verificationSession: VerificationSession)
    case selectMembership(walletSession: WalletConnectSession, verificationSession: VerificationSession)
    
    case selectNFTImage(walletSession: WalletConnectSession,
                        verificationSession: VerificationSession,
                        membershipDuration: UInt32)
    
    case authorizeMinting(walletSession: WalletConnectSession,
                          verificationSession: VerificationSession,
                          selectedImage: TokenImage,
                          membershipDuration: UInt32)
    
    case mintNFT(walletSession: WalletConnectSession,
                 verificationSession: VerificationSession,
                 selectedImage: TokenImage)
    
    case mintingInProgress(walletSession: WalletConnectSession, verificationSession: VerificationSession)
    case startMinting(walletSession: WalletConnectSession, verificationSession: VerificationSession)
    case back
    case exit
}

public class KycDaoViewController: UIViewController {
    
    let navController: UINavigationController
    let connectWalletController: ConnectWalletViewController
    private var disposeBag = Set<AnyCancellable>()
    
    public init() {
        connectWalletController = ConnectWalletViewController()
        navController = UINavigationController(rootViewController: connectWalletController)
        navController.navigationBar.prefersLargeTitles = true
        super.init(nibName: nil, bundle: nil)
        isModalInPresentation = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(navController)
        view.addSubview(navController.view)
        navController.view.frame = view.bounds
        navController.didMove(toParent: self)
        
        view.backgroundColor = .systemBackground
        
        setupNavigator()
        
        print(Locale.isoRegionCodes)
        
    }
    
    private func setupNavigator() {
        
        Page.currentPage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] page in
                self?.navigateTo(page: page)
            }.store(in: &disposeBag)
        
    }
    
    private func navigateTo(page: Page) {
        switch page {
        case .walletSelector(animated: let animated):
            navController.popToRootViewController(animated: animated)
            
        case let .accountSelector(accounts, walletSession):
            
            navController.pushViewController(SelectAccountViewController(accounts: accounts,
                                                                         walletSession: walletSession),
                                             animated: true)
            
        case let .createSignature(walletSession, verificationSession):
            
            navController.pushViewController(CreateSignatureViewController(walletSession: walletSession,
                                                                           verificationSession: verificationSession),
                                             animated: true)
            
        case .informationRequest(walletSession: let walletSession,
                                 verificationSession: let verificationSession):
            
            navController.pushViewController(InformationRequestViewController(walletSession: walletSession,
                                                                              verificationSession: verificationSession),
                                             animated: true)
            
        case .confirmEmail(walletSession: let walletSession,
                           verificationSession: let verificationSession):
            
            navController.pushViewController(ConfirmEmailViewController(walletSession: walletSession,
                                                                        verificationSession: verificationSession),
                                             animated: true)
            
        case let .personaVerification(walletSession, verificationSession):
            
            navController.pushViewController(PersonaViewController(walletSession: walletSession,
                                                                   verificationSession: verificationSession),
                                             animated: true)
            
        case .personaCompletePage(walletSession: let walletSession,
                                  verificationSession: let verificationSession):
            
            navController.pushViewController(PersonaCompleteViewController(walletSession: walletSession,
                                                                           verificationSession: verificationSession),
                                             animated: true)
            
        case .selectMembership(walletSession: let walletSession,
                               verificationSession: let verificationSession):
            
            navController.pushViewController(SelectMembershipViewController(walletSession: walletSession,
                                                                            verificationSession: verificationSession),
                                             animated: true)
            
        case .selectNFTImage(let walletSession,
                             let verificationSession,
                             let membershipDuration):
            
            navController.pushViewController(SelectNFTImageViewController(walletSession: walletSession,
                                                                          verificationSession: verificationSession,
                                                                          membershipDuration: membershipDuration),
                                             animated: true)
        
        case .authorizeMinting(walletSession: let walletSession,
                               verificationSession: let verificationSession,
                               let selectedImage,
                               let membershipDuration):
            
            navController.pushViewController(AuthorizeMintingViewController(walletSession: walletSession,
                                                                            verificationSession: verificationSession,
                                                                            selectedImage: selectedImage,
                                                                            membershipDuration: membershipDuration),
                                             animated: true)
            
        case .mintNFT(let walletSession,
                      let verificationSession,
                      let selectedImage):
            
            navController.pushViewController(MintNFTViewController(walletSession: walletSession,
                                                                   verificationSession: verificationSession,
                                                                   selectedImage: selectedImage),
                                             animated: true)
            
        case .mintingInProgress(let walletSession,
                                let verificationSession):
            
            navController.pushViewController(MintingInProgressViewController(walletSession: walletSession,
                                                                             verificationSession: verificationSession),
                                             animated: true)
            
        case let .startMinting(walletSession, verificationSession):
            
            navController.pushViewController(StartMintingViewController(walletSession: walletSession,
                                                                        verificationSession: verificationSession),
                                             animated: true)
            
        case .back:
            navController.popViewController(animated: true)
            
        case .exit:
            dismiss(animated: true)
            Page.currentPage.send(.walletSelector())
            
        }
    }
    
}
