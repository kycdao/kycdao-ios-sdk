//
//  ClientWrapper.swift
//  
//
//  Created by Vekety Robin on 2022. 06. 21..
//

import Foundation
import WalletConnectSwift
import UIKit
import Combine
import CombineExt

var metamaskMode = true

/// A WalletConnect V1 compatibility support class. Use this, if you want to connect the KYC flow to a Wallet through WalletConnect
public class WalletConnectManager {
    
    /// WalletConnectManager singletion instance
    public static var shared = WalletConnectManager()
    
    private var isListening = false
    
    private typealias DAppInfo = WalletConnectSwift.Session.DAppInfo
    private typealias ClientMeta = WalletConnectSwift.Session.ClientMeta
    
    private static let dAppInfoKey = "kyc.dAppInfoKey"
    private static var dAppInfo: DAppInfo {
        
        if let dappInfoData = UserDefaults.standard.object(forKey: dAppInfoKey) as? Data,
           let savedDappInfo = try? JSONDecoder().decode(DAppInfo.self, from: dappInfoData) {
            return savedDappInfo
        }
        
        let newInfo = DAppInfo(peerId: UUID().uuidString,
                               peerMeta: Self.clientMeta)
        
        if let newInfoData = try? JSONEncoder().encode(newInfo) {
            UserDefaults.standard.set(newInfoData, forKey: dAppInfoKey)
        }
        
        return newInfo
    }
    
    private static let clientMeta = ClientMeta(name: "TestProject",
                                               description: "KYC Dao Test Project",
                                               icons: [],
                                               url: URL(string: "https://staging.kycdao.xyz")!)
    
    private lazy var client: Client = {
        return Client(delegate: self,
                      dAppInfo: Self.dAppInfo)
    }()
    
    private var disposeBag = Set<AnyCancellable>()
    private var pendingSession: PendingSession?
    internal var sessionRepo = SessionRepository.shared
    
    private var nextURL: WCURL = getNewURL()
    
    /// Publisher that emits session objects when connections to wallets are established
    public var sessionStarted: AnyPublisher<WalletSession, Never> {
        sessionStartedSubject.eraseToAnyPublisher()
    }
    
    /// Publisher that emits session URIs on which the WalletConnect component is currently awaiting new connections. Use this publisher when you want to display a QR code to your user. Keep the QR up to date with the URI value received from the publisher.
    public var pendingSessionURI: AnyPublisher<String, Never> {
        pendingSessionURISubject.compactMap { $0 }.eraseToAnyPublisher()
    }
    
    private var sessionStartedSubject = PassthroughSubject<WalletSession, Never>()
    private var pendingSessionURISubject = CurrentValueSubject<String?, Never>(nil)
    
    /// Provides a list of usable wallets for WalletConnect services based on the WalletConnect V1 registry https://registry.walletconnect.com/api/v1/wallets
    /// - Returns: The list of compatible mobile wallets
    public static func listWallets() async throws -> [Wallet] {
        // https://registry.walletconnect.com/api/v1/wallets?entries=5&page=1
        
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://registry.walletconnect.com/api/v1/wallets?entries=100&page=1")!)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KYCError.genericError
        }
        
        guard 200 ... 299 ~= httpResponse.statusCode else {
            throw KYCError.genericError
        }
        
        let listingsDto = try JSONDecoder().decode(ListingsDTO.self, from: data)
        
        print(listingsDto)
        
        guard let listingValues = listingsDto.listings?.values else { return [] }
        let listings = Array(listingValues)
        
        let wcWallets = listings.filter {
            let isEip155Supported = true/*$0.chains?.contains {
                $0.starts(with: "eip155:")
            } ?? false*/
            var mobileSupported = false
            if $0.mobile?.universal != nil || $0.mobile?.native != nil {
                mobileSupported = true
            }
            return isEip155Supported && mobileSupported
        }.map { listing -> Wallet in
            
            var imageURL: URL?
            if let imageURLString = listing.image_url?.lg {
                imageURL = URL(string: imageURLString)
            }
            
            return Wallet(id: listing.id,
                          name: listing.name ?? "",
                          imageURL: imageURL,
                          universalLinkBase: listing.mobile?.universal,
                          deepLinkBase: listing.mobile?.native)
        }.sorted {
            $1.name > $0.name
        }
        
        return wcWallets
    }
    
    
    /// Start listening for incoming connections from wallets
    public func startListening() {
        
        isListening = true
        openNewConnection()
        
    }
    
    //Returns the URI string we are listening on for new connections
    @discardableResult
    func openNewConnection() -> String {
        //Can only fail when next URI collides with an existing one
        //Theoretically near impossible. Booth the 32 byte key and the UUID had to match for this to happen
        do {
            try client.connect(to: nextURL)
            pendingSession = PendingSession(url: nextURL,
                                            wallet: nil,
                                            state: .initialised)
            
            pendingSessionURISubject.send(nextURL.absoluteString)
            
            let pendingURL = nextURL
            nextURL = Self.getNewURL()
            return pendingURL.absoluteString
        } catch let error {
            print("Congrats! You won the lottery with error:\n\(error)\nRetrying again...")
            return openNewConnection()
        }
    }
    
    public func connect(withWallet wallet: Wallet) throws {
        
        guard isListening else { throw KYCError.genericError }
        
        let savedSession = sessionRepo.getSession(walletId: wallet.id)
        let savedSessionIsOpen = client.openSessions().contains(where: { $0.url == savedSession?.url }) == true
        
        if savedSessionIsOpen, let savedSession = savedSession {
            sessionStartedSubject.send(savedSession)
        } else {
            try openWallet(wallet)
        }
    }
    
    func openWallet(_ wallet: Wallet) throws {
        guard let connectionURL = pendingSession?.url.absoluteString
        else {
            throw KYCError.genericError
        }
        
//        if metamaskMode {
            try openWalletDeepLinkFirst(wallet: wallet, connectionURL: connectionURL)
//        } else {
//            try openWalletUniversalLinkFirst(wallet: wallet, connectionURL: connectionURL)
//        }
        
    }
        
    private func openWalletUniversalLinkFirst(wallet: Wallet, connectionURL: String) throws {
        if let universalLink = wallet.universalLinkBase,
           let url = URL(string: "\(universalLink)/wc?uri=\(connectionURL)") {
            print(url.absoluteString)
            UIApplication.shared.open(url)
            pendingSession?.wallet = wallet

        } else if let deepLink = wallet.deepLinkBase,
                  deepLink.hasSuffix(":"),
                  let url = URL(string: "\(deepLink)//wc?uri=\(connectionURL)") {
            print(url.absoluteString)
            UIApplication.shared.open(url)
            pendingSession?.wallet = wallet

        } else if let deepLink = wallet.deepLinkBase,
                  let url = URL(string: "\(deepLink)/wc?uri=\(connectionURL)") {
            print(url.absoluteString)
            UIApplication.shared.open(url)
            pendingSession?.wallet = wallet

        } else {

            throw KYCError.genericError

        }
    }
        
    private func openWalletDeepLinkFirst(wallet: Wallet, connectionURL: String) throws {
        
        if let deepLink = wallet.deepLinkBase,
                  deepLink.hasSuffix(":"),
                  let url = URL(string: "\(deepLink)//wc?uri=\(connectionURL)") {
            print(url.absoluteString)
            UIApplication.shared.open(url)
            pendingSession?.wallet = wallet
            
        } else if let deepLink = wallet.deepLinkBase,
                  let url = URL(string: "\(deepLink)/wc?uri=\(connectionURL)") {
            print(url.absoluteString)
            UIApplication.shared.open(url)
            pendingSession?.wallet = wallet
            
        } else if let universalLink = wallet.universalLinkBase,
           let url = URL(string: "\(universalLink)/wc?uri=\(connectionURL)") {
            print(url.absoluteString)
            UIApplication.shared.open(url)
            pendingSession?.wallet = wallet
        } else {
            
            throw KYCError.genericError
            
        }
        
    }
    
    func sign(account: String, message: String, url: WCURL) async throws -> String {
        
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<String, Error>) in
            do {
                try self?.client.personal_sign(url: url, message: message, account: account) { response in
                    do {
                        if let error = response.error {
                            throw error
                        } else {
                            let signature = try response.result(as: String.self)
                            continuation.resume(returning: signature)
                        }
                    } catch let error {
                        continuation.resume(throwing: KYCError.walletConnect(.signingError(error.localizedDescription)))
                    }
                }
            } catch let error {
                continuation.resume(throwing: KYCError.walletConnect(.signingError(error.localizedDescription)))
            }
        }
    }
    
    func sign(account: String, message: String, wallet: Wallet) async throws -> String {
        
        let session = sessionRepo.getSession(walletId: wallet.id)
        guard let url = session?.url else { throw KYCError.genericError }
        
        return try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<String, Error>) in
            do {
                try self?.client.personal_sign(url: url, message: message, account: account) { response in
                    do {
                        if let error = response.error {
                            throw error
                        } else {
                            let signature = try response.result(as: String.self)
                            continuation.resume(returning: signature)
                        }
                    } catch let error {
                        continuation.resume(throwing: KYCError.walletConnect(.signingError(error.localizedDescription)))
                    }
                }
                
//                guard let link = wallet.universalLinkBase ?? wallet.deepLinkBase,
                guard let link = wallet.deepLinkBase ?? wallet.universalLinkBase,
                      let linkURL = URL(string: "\(link)//wc") else {
                    throw KYCError.genericError
                }
                
                Task { @MainActor in
                    UIApplication.shared.open(linkURL)
                }
            } catch let error {
                continuation.resume(throwing: KYCError.walletConnect(.signingError(error.localizedDescription)))
            }
        }
    }
    
    func sendTransaction(transaction: Client.Transaction, url: WCURL) async throws -> String {
        
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<String, Error>) in
            do {
                try self?.client.eth_sendTransaction(url: url, transaction: transaction) { response in
                    do {
                        if let error = response.error {
                            throw error
                        } else {
                            let transactionResult = try response.result(as: String.self)
                            continuation.resume(returning: transactionResult)
                        }
                    } catch let error {
                        continuation.resume(throwing: KYCError.walletConnect(.signingError(error.localizedDescription)))
                    }
                }
            } catch let error {
                continuation.resume(throwing: KYCError.walletConnect(.signingError(error.localizedDescription)))
            }
        }
    }
    
    func sendTransaction(transaction: Client.Transaction, wallet: Wallet) async throws -> String {
        
        let session = sessionRepo.getSession(walletId: wallet.id)
        guard let url = session?.url else { throw KYCError.genericError }
        
        return try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<String, Error>) in
            do {
                try self?.client.eth_sendTransaction(url: url, transaction: transaction) { response in
                    do {
                        if let error = response.error {
                            throw error
                        } else {
                            let transactionResult = try response.result(as: String.self)
                            continuation.resume(returning: transactionResult)
                        }
                    } catch let error {
                        continuation.resume(throwing: KYCError.walletConnect(.signingError(error.localizedDescription)))
                    }
                }
                
//                guard let link = wallet.universalLinkBase ?? wallet.deepLinkBase,
                guard let link = wallet.deepLinkBase ?? wallet.universalLinkBase,
                      let linkURL = URL(string: "\(link)/wc") else {
                    throw KYCError.genericError
                }
                
                Task { @MainActor in
                    UIApplication.shared.open(linkURL)
                }
            } catch let error {
                continuation.resume(throwing: KYCError.walletConnect(.signingError(error.localizedDescription)))
            }
        }
    }
    
    private static func getNewURL() -> WCURL {
        WCURL(topic: UUID().uuidString,
              bridgeURL: URL(string: "https://safe-walletconnect.gnosis.io/")!,
//              bridgeURL: URL(string: "https://bridge.walletconnect.org")!,
              key: randomKey())
    }
    
    // https://developer.apple.com/documentation/security/1399291-secrandomcopybytes
    // SecRandomCopyBytes is more secure but can fail. Falling back to less secure arc4random_buf in case of failure.
    private static func randomKey() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status == errSecSuccess {
            return Data(bytes: bytes, count: 32).toHexString()
        } else {
            bytes = [UInt8](repeating: 0, count: 32)
            arc4random_buf(&bytes, bytes.count)
            return Data(bytes: bytes, count: 32).toHexString()
        }
    }
    
}



extension WalletConnectManager: ClientDelegate {
    
    public func client(_ client: Client, didFailToConnect url: WCURL) {
        print("didFail \(url)")
        if let pendingSession = pendingSession, pendingSession.url == url {
            openNewConnection()
        }
    }
    
    public func client(_ client: Client, didConnect url: WCURL) {
        print("didConnect wculr \(url)")
    }
    
    public func client(_ client: Client, didConnect session: WCSession) {
        print("didConnect session \(session.url)")
        print("session: \(session)")
        
        let newSessionSameAsPending = pendingSession?.url == session.url
                                      && !sessionRepo.containsSession(withURL: session.url)
        
        if let pendingSession = pendingSession, newSessionSameAsPending {
            let walletSession = try? WalletSession(session: session,
                                                   wallet: pendingSession.wallet,
                                                   status: .active,
                                                   state: .connected)
            guard let walletSession = walletSession else { return }
            
            sessionRepo.addSession(walletSession)
            sessionStartedSubject.send(walletSession)
            openNewConnection()
        }
    }
    
    public func client(_ client: Client, didDisconnect session: WCSession) {
        print("didDisconnect \(session.url)")
        sessionRepo.deleteSession(session)
    }
    
    public func client(_ client: Client, didUpdate session: WCSession) {
        print("didUpdate \(session.url)")
        sessionRepo.updateSession(session)
    }
    
}
