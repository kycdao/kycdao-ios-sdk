//
//  File.swift
//  
//
//  Created by Vekety Robin on 2022. 06. 17..
//

import Foundation
import UIKit
import Combine

enum Page {
    static let currentPage = CurrentValueSubject<Page, Never>(.walletSelector())
    
    case walletSelector(animated: Bool = false)
    case accountSelector(accounts: [String], walletSession: WalletConnectSession)
    case createSignature(walletSession: WalletConnectSession, verificationSession: VerificationSession)
    case informationRequest(walletSession: WalletConnectSession, verificationSession: VerificationSession)
    case confirmEmail(walletSession: WalletConnectSession, verificationSession: VerificationSession)
    case personaVerification(walletSession: WalletConnectSession, verificationSession: VerificationSession)
    case personaCompletePage(walletSession: WalletConnectSession, verificationSession: VerificationSession)
    case authorizeMinting(walletSession: WalletConnectSession, verificationSession: VerificationSession, selectedImage: TokenImage)
    case selectNFTImage(walletSession: WalletConnectSession, verificationSession: VerificationSession)
    case mintNFT(walletSession: WalletConnectSession, verificationSession: VerificationSession, selectedImage: TokenImage)
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
        
        
//        //Display QR code using URI, etc
//        let uri = WalletConnectManager.shared.startListening()
//
//        let wallets = WalletConnectManager.listWallets()
//        WalletConnectManager.shared.openWallet(wallets[0]!)
//
//        WalletConnectManager.shared.sessionStarted.sink { walletSession in
//            Task {
//
//                let verificationSession = try await VerificationManager.shared.createSession(walletAddress: walletSession.accounts![0],
//                                                                           network: Network(chainId: walletSession.chainId!)!)
//
//                let signature = try await walletSession.sign(account: walletSession.accounts![0], message: verificationSession.loginProof)
//
//                if !verificationSession.isLoggedIn {
//                    try await verificationSession.login(signature: signature)
//                }
//
//                if !verificationSession.requiredInformationProvided {
//                    try await verificationSession.updateUser(email: "", residency: "hu-HU", legalEntity: false)
//                    try await verificationSession.acceptDisclaimer()
//                }
//
//                if !verificationSession.emailProvided {
//                    try await verificationSession.sendConfirmationEmail()
//                    try await verificationSession.continueWhenEmailConfirmed()
//                }
//
//                try await verificationSession.startIdentification(fromViewController: self)
//                try await verificationSession.continueWhenIdentified()
//                let nftImages = try await verificationSession.getNFTImages()
//                let mintingAuth = try await verificationSession.requestMinting(selectedImageId: nftImages.first!.id)
//
//                //Only for displaying on UI, use estimatedGas.feeInNative for displaying it in a readable format
//                let estimatedGas = try await verificationSession.estimateGasForMinting()
//
//                try await verificationSession.mint(performTransaction: { mintingProperties in
//                    let txHash = try await walletSession.sendMintingTransaction(mintingProperties: mintingProperties)
//                    return MintingTransactionResult(txHash: txHash)
//                })
//            }
//        }
        
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
            navController.pushViewController(SelectAccountViewController(accounts: accounts, walletSession: walletSession), animated: true)
        case let .createSignature(walletSession, verificationSession):
            navController.pushViewController(CreateSignatureViewController(walletSession: walletSession, verificationSession: verificationSession), animated: true)
        case .informationRequest(walletSession: let walletSession, verificationSession: let verificationSession):
            navController.pushViewController(InformationRequestViewController(walletSession: walletSession, verificationSession: verificationSession), animated: true)
        case .confirmEmail(walletSession: let walletSession, verificationSession: let verificationSession):
            navController.pushViewController(ConfirmEmailViewController(walletSession: walletSession, verificationSession: verificationSession), animated: true)
        case let .personaVerification(walletSession, verificationSession):
            navController.pushViewController(PersonaViewController(walletSession: walletSession, verificationSession: verificationSession), animated: true)
        case .personaCompletePage(walletSession: let walletSession, verificationSession: let verificationSession):
            navController.pushViewController(PersonaCompleteViewController(walletSession: walletSession, verificationSession: verificationSession), animated: true)
        case .authorizeMinting(walletSession: let walletSession, verificationSession: let verificationSession, let selectedImage):
            navController.pushViewController(AuthorizeMintingViewController(walletSession: walletSession, verificationSession: verificationSession, selectedImage: selectedImage), animated: true)
        case .selectNFTImage(let walletSession, let verificationSession):
            navController.pushViewController(SelectNFTImageViewController(walletSession: walletSession, verificationSession: verificationSession), animated: true)
        case .mintNFT(let walletSession, let verificationSession, let selectedImage):
            navController.pushViewController(MintNFTViewController(walletSession: walletSession, verificationSession: verificationSession, selectedImage: selectedImage), animated: true)
        case .mintingInProgress(let walletSession, let verificationSession):
            navController.pushViewController(MintingInProgressViewController(walletSession: walletSession, verificationSession: verificationSession), animated: true)
        case let .startMinting(walletSession, verificationSession):
            navController.pushViewController(StartMintingViewController(walletSession: walletSession, verificationSession: verificationSession), animated: true)
        case .back:
            navController.popViewController(animated: true)
        case .exit:
            dismiss(animated: true)
        }
    }
    
}
