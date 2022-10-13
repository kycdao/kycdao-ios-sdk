//
//  ConnectWalletViewController.swift
//  
//
//  Created by Vekety Robin on 2022. 06. 20..
//

import Foundation
import UIKit
import CoreImage.CIFilterBuiltins
import Combine
import WalletConnectSwift

private enum WalletListSection: Int, CaseIterable {
    case main
}

class ConnectWalletViewController: UIViewController, UICollectionViewDelegate, UIToolbarDelegate, UIScrollViewDelegate {
    
    private var disposeBag = Set<AnyCancellable>()
    
    let walletGrid: UICollectionView
    let contentView = UIView()
    let scrollView = UIScrollView()

    let qrContainer = UIView()
    let qrContent = UIView()
    let qrImageView = UIImageView()
    let qrOrLabel = UILabel()
    let qrCopyURI = SimpleButton()
    
    var contentHeightConstraint: NSLayoutConstraint?
    var qrContainerBottomConstraint: NSLayoutConstraint?
    
    let segmentControl = UISegmentedControl(items: ["Select wallet", "Use QR"])
    let toolbar = UIToolbar()
    
    var uri: String? {
        didSet {
            guard let uri = uri else { return }
            setQR(code: uri)
        }
    }
    
    private typealias WalletDataSource = UICollectionViewDiffableDataSource<WalletListSection, Wallet>
    private let dataSource: WalletDataSource
    
    let compositionalLayout: UICollectionViewCompositionalLayout = {
        let fraction: CGFloat = 1 / 4
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(fraction))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 0)
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 16
        
        return UICollectionViewCompositionalLayout(section: section, configuration: config)
    }()
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        DispatchQueue.main.async {
            print("wallet grid size: \(self.walletGrid.contentSize.height > 0) \(self.walletGrid.contentSize.height)")
            self.contentHeightConstraint?.constant = self.walletGrid.contentSize.height > 0 ? self.walletGrid.contentSize.height : self.view.frame.height
        }
    }
    
    public init() {
        
        walletGrid = UICollectionView(frame: .zero,
                                      collectionViewLayout: compositionalLayout)
        
        walletGrid.bounces = true
        
        dataSource = WalletDataSource(collectionView: walletGrid) { collectionView, indexPath, wallet in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WalletCell", for: indexPath) as! WalletCell
            cell.walletLabel.text = wallet.name
            cell.imageURL = wallet.imageURL
            return cell
        }
        
        super.init(nibName: nil, bundle: nil)
        
        scrollView.delegate = self
        walletGrid.delegate = self
        
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self,
                                 action: #selector(didTapSegmentedControl),
                                 for: .primaryActionTriggered)
        
        let barItem = UIBarButtonItem(customView: segmentControl)
        toolbar.setItems([barItem], animated: false)
        
        qrCopyURI.addTarget(self, action: #selector(copyURITap(_:)), for: .touchUpInside)
        
        WalletConnectManager.shared.startListening()
        
        WalletConnectManager.shared.pendingSessionURI
            .receive(on: DispatchQueue.main)
            .sink { uri in
                self.uri = uri
            }.store(in: &disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Connect to wallet"
        view.backgroundColor = .systemBackground
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(walletGrid)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        walletGrid.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentInset = .init(top: 44, left: 0, bottom: 0, right: 0)
        
        scrollView.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.isTranslucent = false
        
        contentView.addSubview(qrContainer)
        qrContainer.translatesAutoresizingMaskIntoConstraints = false
        qrContainer.addSubview(qrContent)
        qrContent.translatesAutoresizingMaskIntoConstraints = false
        qrContent.addSubview(qrImageView)
        qrImageView.translatesAutoresizingMaskIntoConstraints = false
        qrContent.addSubview(qrOrLabel)
        qrOrLabel.translatesAutoresizingMaskIntoConstraints = false
        qrContent.addSubview(qrCopyURI)
        qrCopyURI.translatesAutoresizingMaskIntoConstraints = false
        
        qrOrLabel.text = "or"
        qrCopyURI.setTitle("Copy URI", for: .normal)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.widthAnchor.constraint(equalTo: view.widthAnchor),
            
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            walletGrid.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            walletGrid.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            walletGrid.topAnchor.constraint(equalTo: contentView.topAnchor),
            walletGrid.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            walletGrid.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            walletGrid.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            
            toolbar.topAnchor.constraint(equalTo: walletGrid.topAnchor, constant: -40),
            toolbar.leadingAnchor.constraint(equalTo: walletGrid.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: walletGrid.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),
            toolbar.widthAnchor.constraint(equalTo: walletGrid.widthAnchor),
            
            qrContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            qrContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            qrContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            qrContainer.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            
            qrContent.topAnchor.constraint(equalTo: qrContainer.topAnchor),
            qrContent.leadingAnchor.constraint(equalTo: qrContainer.leadingAnchor),
            qrContent.trailingAnchor.constraint(equalTo: qrContainer.trailingAnchor),
            qrContent.bottomAnchor.constraint(lessThanOrEqualTo: qrContainer.bottomAnchor),
            
            qrImageView.topAnchor.constraint(equalTo: qrContent.topAnchor, constant: 20),
            qrImageView.leadingAnchor.constraint(greaterThanOrEqualTo: qrContent.leadingAnchor),
            qrImageView.trailingAnchor.constraint(lessThanOrEqualTo: qrContent.trailingAnchor),
//            qrImageView.bottomAnchor.constraint(equalTo: qrContent.bottomAnchor),
            qrImageView.centerXAnchor.constraint(equalTo: qrContent.centerXAnchor),
            qrImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            qrImageView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            
            qrOrLabel.topAnchor.constraint(equalTo: qrImageView.bottomAnchor, constant: 20),
            qrOrLabel.leadingAnchor.constraint(greaterThanOrEqualTo: qrImageView.leadingAnchor),
            qrOrLabel.trailingAnchor.constraint(lessThanOrEqualTo: qrImageView.trailingAnchor),
            qrOrLabel.centerXAnchor.constraint(equalTo: qrContent.centerXAnchor),
            
            qrCopyURI.topAnchor.constraint(equalTo: qrOrLabel.bottomAnchor, constant: 20),
            qrCopyURI.leadingAnchor.constraint(greaterThanOrEqualTo: qrImageView.leadingAnchor),
            qrCopyURI.trailingAnchor.constraint(lessThanOrEqualTo: qrImageView.trailingAnchor),
            qrCopyURI.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            qrCopyURI.heightAnchor.constraint(equalToConstant: 40),
            qrCopyURI.centerXAnchor.constraint(equalTo: qrContent.centerXAnchor),
            qrCopyURI.bottomAnchor.constraint(equalTo: qrContent.bottomAnchor),
        ])
        
        qrContainerBottomConstraint = qrContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        contentHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: 100)
        contentHeightConstraint?.isActive = true
        
        walletGrid.isScrollEnabled = false
        walletGrid.bounces = false
        walletGrid.register(WalletCell.self, forCellWithReuseIdentifier: "WalletCell")
        
        navigationController?.navigationBar.prefersLargeTitles = true
        qrContainer.transform = .init(translationX: view.frame.width, y: 0)
        
        Task {
            let wallets = try await WalletConnectManager.listWallets()
            var snapshot = NSDiffableDataSourceSnapshot<WalletListSection, Wallet>()
            snapshot.appendSections([.main])
            snapshot.appendItems(wallets)
            dataSource.apply(snapshot, animatingDifferences: false)
        }
        
        WalletConnectManager.shared.sessionStarted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] walletSession in
                self?.sessionStarted(walletSession)
            }.store(in: &disposeBag)
        
    }
    
    func sessionStarted(_ walletSession: WalletSession) {
        let accounts = walletSession.accounts
        if accounts.count > 1 {
            
            Page.currentPage.send(.accountSelector(accounts: accounts, walletSession: walletSession))
        
        } else if let singleAccount = accounts.first {
            
            Task {
                
                let kycSession = try await KYCManager.shared.createSession(walletAddress: singleAccount, walletSession: walletSession)
                
                if kycSession.isLoggedIn {
                    
                    if kycSession.requiredInformationProvided {
                        
                        if kycSession.emailConfirmed {
                            
                            switch kycSession.verificationStatus {
                            case .verified:
                                Page.currentPage.send(.selectNFTImage(walletSession: walletSession, kycSession: kycSession))
                            case .processing:
                                Page.currentPage.send(.personaCompletePage(walletSession: walletSession, kycSession: kycSession))
                            case .notVerified:
                                Page.currentPage.send(.personaVerification(walletSession: walletSession, kycSession: kycSession))
                            }
                            
                        } else {
                            
                            Page.currentPage.send(.confirmEmail(walletSession: walletSession, kycSession: kycSession))
                        }
                        
                    } else {
                        
                        Page.currentPage.send(.informationRequest(walletSession: walletSession, kycSession: kycSession))
                    }
                    
                } else {
                    Page.currentPage.send(.createSignature(walletSession: walletSession, kycSession: kycSession))
                }
                
            }
        }
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        scrollView.scrollIndicatorInsets = .init(top: self.view.safeAreaInsets.top, left: 0, bottom: 0, right: 0)
    }
    
    @objc private func didTapSegmentedControl(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            showAppGrid()
        case 1:
            showQR()
        default:
            break
        }
    }
    
    @objc func copyURITap(_ sender: Any) {
        UIPasteboard.general.string = self.uri
    }
    
    func setQR(code: String) {
        let data = Data(code.utf8)
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")

        let outputImage = filter.outputImage!
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 4, y: 4))
        let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent)!
        
        qrImageView.layer.magnificationFilter = CALayerContentsFilter.nearest
        qrImageView.image = UIImage(cgImage: cgImage)
    }
    
    func showAppGrid() {
        qrContainerBottomConstraint?.isActive = false
        contentHeightConstraint?.isActive = true
        UIView.animate(withDuration: 0.4) {
            self.view.layoutIfNeeded()
            self.qrContainer.transform = .init(translationX: self.view.frame.width, y: 0)
            self.walletGrid.transform = .identity
        }
    }
    
    func showQR() {
        qrContainerBottomConstraint?.isActive = true
        contentHeightConstraint?.isActive = false
        UIView.animate(withDuration: 0.4) {
            self.view.layoutIfNeeded()
            self.qrContainer.transform = .identity
            self.walletGrid.transform = .init(translationX: -self.view.frame.width, y: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let wallet = dataSource.itemIdentifier(for: indexPath) {
            do {
                try WalletConnectManager.shared.connect(withWallet: wallet)
            } catch let error {
                
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.async {
            print("wallet grid size: \(self.walletGrid.contentSize.height > 0) \(self.walletGrid.contentSize.height)")
            self.contentHeightConstraint?.constant = self.walletGrid.contentSize.height > 0 ? self.walletGrid.contentSize.height : self.view.frame.height
        }
    }
    
}
