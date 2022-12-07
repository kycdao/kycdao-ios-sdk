//
//  SelectAccountViewController.swift
//  
//
//  Created by Vekety Robin on 2022. 06. 21..
//

import Foundation
import UIKit
import KycDao

private enum AccountsSection: Int, CaseIterable {
    case main
}

class SelectAccountViewController: UIViewController, UITableViewDelegate {
    
    let accountsTableView = UITableView()
    let selectAccountButton = SimpleButton()
    
    private var dataSource: UITableViewDiffableDataSource<AccountsSection, String>?
    private var selectedAccount: String? {
        didSet {
            selectAccountButton.isEnabled = selectedAccount != nil
        }
    }
    private var accounts: [String]
    private var walletSession: WalletConnectSession
    
    init(accounts: [String], walletSession: WalletConnectSession) {
        self.accounts = accounts
        self.walletSession = walletSession
        super.init(nibName: nil, bundle: nil)
        
        accountsTableView.delegate = self
        accountsTableView.allowsMultipleSelection = false
        accountsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "AccountCell")
        accountsTableView.contentInset = .init(top: 0, left: 0, bottom: 70, right: 0)
        
        dataSource = UITableViewDiffableDataSource(tableView: accountsTableView) { tableView, indexPath, account in
            let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath)
            cell.selectionStyle = .none
            cell.textLabel?.text = account
            if self.selectedAccount == account {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            return cell
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select an account"
        view.backgroundColor = .systemBackground
        
        selectAccountButton.isEnabled = false
        selectAccountButton.setTitle("Next", for: .normal)
        selectAccountButton.addTarget(self, action: #selector(nextTapped(_:)), for: .touchUpInside)
        
        view.addSubview(accountsTableView)
        view.addSubview(selectAccountButton)
        
        accountsTableView.translatesAutoresizingMaskIntoConstraints = false
        selectAccountButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            accountsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            accountsTableView.topAnchor.constraint(equalTo: view.topAnchor),
            accountsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            accountsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            selectAccountButton.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: view.leadingAnchor, multiplier: 1),
            selectAccountButton.trailingAnchor.constraint(lessThanOrEqualToSystemSpacingAfter: view.trailingAnchor, multiplier: 1),
            selectAccountButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectAccountButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            selectAccountButton.heightAnchor.constraint(equalToConstant: 40),
            selectAccountButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
        ])
        
        var snapshot = NSDiffableDataSourceSnapshot<AccountsSection, String>()
        snapshot.appendSections([.main])
        snapshot.appendItems(accounts/* + ["0x6178268124124", "0x786147824", "0x788D87ADS",
                              "0x617826812412", "0x78614782", "0x788D87AD",
                              "0x6178268124121", "0x786147821", "0x788D87AD1",
                              "0x6178268124122", "0x786147822", "0x788D87AD2",
                              "0x6178268124123", "0x786147823", "0x788D87AD3",
                             ]*/)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let account = dataSource?.itemIdentifier(for: indexPath) else { return }
        
        var previousSelectedCell: UITableViewCell? = nil
        if let selectedAccount = selectedAccount,
           let selectedPath = dataSource?.indexPath(for: selectedAccount) {
            previousSelectedCell = tableView.cellForRow(at: selectedPath)
        }
        
        selectedAccount = selectedAccount != account ? account : nil
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = selectedAccount != nil ? .checkmark : .none
        previousSelectedCell?.accessoryType = .none
    }
    
    @objc func nextTapped(_ sender: Any) {
        
        guard let selectedAccount = selectedAccount else {
            return
        }
        
        Task {
            
            var verificationSession: VerificationSession
            
            do {
            
                verificationSession = try await VerificationManager.shared.createSession(walletAddress: selectedAccount, walletSession: walletSession)
            
            } catch let error {
                print(error)
                throw error
            }
            
            if verificationSession.loggedIn {
                if verificationSession.requiredInformationProvided {
                    if verificationSession.emailConfirmed {

                        switch verificationSession.verificationStatus {
                        case .verified:
                            if verificationSession.hasMembership {
                                Page.currentPage.send(.selectNFTImage(walletSession: walletSession, verificationSession: verificationSession, membershipDuration: 0))
                            } else {
                                Page.currentPage.send(.selectMembership(walletSession: walletSession, verificationSession: verificationSession))
                            }
                        case .processing:
                            Page.currentPage.send(.personaCompletePage(walletSession: walletSession, verificationSession: verificationSession))
                        case .notVerified:
                            Page.currentPage.send(.personaVerification(walletSession: walletSession, verificationSession: verificationSession))
                        }

                    } else {
                        Page.currentPage.send(.confirmEmail(walletSession: walletSession, verificationSession: verificationSession))
                    }

                } else {
                    Page.currentPage.send(.informationRequest(walletSession: walletSession, verificationSession: verificationSession))
                }
            } else {
                Page.currentPage.send(.createSignature(walletSession: walletSession, verificationSession: verificationSession))
            }
            
        }
        
    }
    
}
