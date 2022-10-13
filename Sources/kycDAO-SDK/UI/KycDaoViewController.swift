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
    case accountSelector(accounts: [String], walletSession: WalletSession)
    case createSignature(walletSession: WalletSession, kycSession: KYCSession)
    case informationRequest(walletSession: WalletSession, kycSession: KYCSession)
    case confirmEmail(walletSession: WalletSession, kycSession: KYCSession)
    case personaVerification(walletSession: WalletSession, kycSession: KYCSession)
    case personaCompletePage(walletSession: WalletSession, kycSession: KYCSession)
    case authorizeMinting(walletSession: WalletSession, kycSession: KYCSession, selectedImage: TokenImage)
    case selectNFTImage(walletSession: WalletSession, kycSession: KYCSession)
    case mintNFT(walletSession: WalletSession, kycSession: KYCSession, selectedImage: TokenImage)
    case mintingInProgress(walletSession: WalletSession, kycSession: KYCSession)
    case startMinting(walletSession: WalletSession, kycSession: KYCSession)
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
//                let kycSession = try await KYCManager.shared.createSession(walletAddress: walletSession.accounts![0],
//                                                                           network: Network(chainId: walletSession.chainId!)!)
//
//                let signature = try await walletSession.sign(account: walletSession.accounts![0], message: kycSession.loginProof)
//
//                if !kycSession.isLoggedIn {
//                    try await kycSession.login(signature: signature)
//                }
//
//                if !kycSession.requiredInformationProvided {
//                    try await kycSession.updateUser(email: "", residency: "hu-HU", legalEntity: false)
//                    try await kycSession.acceptDisclaimer()
//                }
//
//                if !kycSession.emailProvided {
//                    try await kycSession.sendConfirmationEmail()
//                    try await kycSession.continueWhenEmailConfirmed()
//                }
//
//                try await kycSession.startIdentification(fromViewController: self)
//                try await kycSession.continueWhenIdentified()
//                let nftImages = try await kycSession.getNFTImages()
//                let mintingAuth = try await kycSession.requestMinting(selectedImageId: nftImages.first!.id)
//
//                //Only for displaying on UI, use estimatedGas.feeInNative for displaying it in a readable format
//                let estimatedGas = try await kycSession.estimateGasForMinting()
//
//                try await kycSession.mint(performTransaction: { mintingProperties in
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
        case let .createSignature(walletSession, kycSession):
            navController.pushViewController(CreateSignatureViewController(walletSession: walletSession, kycSession: kycSession), animated: true)
        case .informationRequest(walletSession: let walletSession, kycSession: let kycSession):
            navController.pushViewController(InformationRequestViewController(walletSession: walletSession, kycSession: kycSession), animated: true)
        case .confirmEmail(walletSession: let walletSession, kycSession: let kycSession):
            navController.pushViewController(ConfirmEmailViewController(walletSession: walletSession, kycSession: kycSession), animated: true)
        case let .personaVerification(walletSession, kycSession):
            navController.pushViewController(PersonaViewController(walletSession: walletSession, kycSession: kycSession), animated: true)
        case .personaCompletePage(walletSession: let walletSession, kycSession: let kycSession):
            navController.pushViewController(PersonaCompleteViewController(walletSession: walletSession, kycSession: kycSession), animated: true)
        case .authorizeMinting(walletSession: let walletSession, kycSession: let kycSession, let selectedImage):
            navController.pushViewController(AuthorizeMintingViewController(walletSession: walletSession, kycSession: kycSession, selectedImage: selectedImage), animated: true)
        case .selectNFTImage(let walletSession, let kycSession):
            navController.pushViewController(SelectNFTImageViewController(walletSession: walletSession, kycSession: kycSession), animated: true)
        case .mintNFT(let walletSession, let kycSession, let selectedImage):
            navController.pushViewController(MintNFTViewController(walletSession: walletSession, kycSession: kycSession, selectedImage: selectedImage), animated: true)
        case .mintingInProgress(let walletSession, let kycSession):
            navController.pushViewController(MintingInProgressViewController(walletSession: walletSession, kycSession: kycSession), animated: true)
        case let .startMinting(walletSession, kycSession):
            navController.pushViewController(StartMintingViewController(walletSession: walletSession, kycSession: kycSession), animated: true)
        case .back:
            navController.popViewController(animated: true)
        case .exit:
            dismiss(animated: true)
        }
    }
    
}
