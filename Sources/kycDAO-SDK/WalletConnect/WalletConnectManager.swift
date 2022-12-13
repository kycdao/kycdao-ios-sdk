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

/// A WalletConnect V1 compatibility support class. Use this, if you want to connect the verification flow to a wallet through WalletConnect
public class WalletConnectManager {
    
    /// A successfully connected ``WalletConnectSession`` or a failed connection with ``WalletConnectError``
    public typealias SessionStartResult = Result<WalletConnectSession, WalletConnectError>
    
    /// WalletConnectManager singleton instance
    public static var shared = WalletConnectManager()
    
    private var isListening = false
    
    private typealias DAppInfo = WalletConnectSwift.Session.DAppInfo
    private typealias ClientMeta = WalletConnectSwift.Session.ClientMeta
    
    private static let dAppPeerIdKey = "kyc.peerIdKey"
    private static var dAppInfo: DAppInfo {
        
        if let savedPeerId = UserDefaults.standard.string(forKey: dAppPeerIdKey) {
            let info = DAppInfo(peerId: savedPeerId,
                                peerMeta: Self.clientMeta)
            return info
        }
        
        let newPeerId = UUID().uuidString
        let newInfo = DAppInfo(peerId: newPeerId,
                               peerMeta: Self.clientMeta)
        
        if let newPeerIdData = try? JSONEncoder().encode(newPeerId) {
            UserDefaults.standard.set(newPeerIdData, forKey: dAppPeerIdKey)
        }
        
        return newInfo
    }
    
    private static let clientMeta = ClientMeta(name: "kycDAO",
                                               description: nil,
                                               icons: [URL(string: "https://avatars.githubusercontent.com/u/87816891?s=200&v=4")!],
                                               url: URL(string: "https://kycdao.xyz")!)
    
    private lazy var client: Client = {
        return Client(delegate: self,
                      dAppInfo: Self.dAppInfo)
    }()
    
    private var disposeBag = Set<AnyCancellable>()
    private var pendingSession: PendingSession?
    internal var sessionRepo = SessionRepository.shared
    
    private var nextURL: WCURL = getNewURL()
    
    /// Publisher that emits session objects when connections to wallets are established or failed
    ///
    /// You can unwrap the contained session object or error like
    /// ```swift
    /// let result: SessionStartResult = ...
    /// switch result {
    /// case .success(let walletSession):
    ///     // Do something with `walletSession`
    /// case .failure(WalletConnectError.failedToConnect(let wallet)):
    ///     print("Could not connect to \(wallet?.name ?? "unkown wallet")")
    /// default:
    ///     break
    /// }
    /// ```
    public var sessionStart: AnyPublisher<SessionStartResult, Never> {
        sessionStartedSubject.eraseToAnyPublisher()
    }
    
    /// Publisher that emits session URIs on which the WalletConnect component is currently awaiting new connections.
    /// - Note: Use this publisher when you want to display a QR code to your user. Keep the QR up to date with the URI value received from the publisher.
    public var pendingSessionURI: AnyPublisher<String?, Never> {
        pendingSessionURISubject.eraseToAnyPublisher()
    }
    
    private var sessionStartedSubject = PassthroughSubject<Result<WalletConnectSession, WalletConnectError>, Never>()
    private var pendingSessionURISubject = CurrentValueSubject<String?, Never>(nil)
    
    /// Provides a list of usable wallets for WalletConnect services based on the [WalletConnect V1 registry](https://registry.walletconnect.com/api/v1/wallets)
    /// - Returns: The list of compatible mobile wallets
    ///
    /// - Note: This is a filtered list of wallets, and may not contain every wallet the registry returns
    public static func listWallets() async throws -> [Wallet] {
        // https://registry.walletconnect.com/api/v1/wallets?entries=5&page=1
        
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://registry.walletconnect.com/api/v1/wallets?entries=1000&page=1")!)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KycDaoError.genericError
        }
        
        guard 200 ... 299 ~= httpResponse.statusCode else {
            throw KycDaoError.genericError
        }
        
        let listingsDto = try JSONDecoder().decode(ListingsDTO.self, from: data)
        
        print(listingsDto)
        
        guard let listingValues = listingsDto.listings?.values else { return [] }
        let listings = Array(listingValues)
        
        let wcWallets = listings.filter {
//            let isEip155Supported = $0.chains?.contains {
//                $0.starts(with: "eip155:")
//            } ?? false
            var mobileSupported = false
            if $0.mobile?.universal?.isEmpty == false || $0.mobile?.native?.isEmpty == false {
                mobileSupported = true
            }
            // Wallet connect V1 registry is not properly maintained and is inappropriate for building any serious filtering around chainIds...
            return /*isEip155Supported &&*/ mobileSupported
        }.map { listing -> Wallet in
            
            var imageURL: URL?
            if let imageURLString = listing.image_url?.lg {
                imageURL = URL(string: imageURLString)
            }
            
            var universalLinkBase: String?
            var deepLinkBase: String?
            
            if let universal = listing.mobile?.universal {
                universalLinkBase = "\(universal)/wc"
            }
            
            if let deepLink = listing.mobile?.native, deepLink.hasSuffix(":") {
                deepLinkBase = "\(deepLink)//wc"
            } else if let deepLink = listing.mobile?.native {
                deepLinkBase = "\(deepLink)/wc"
            }
            
            return Wallet(id: listing.id,
                          name: listing.metadata?.shortName ?? listing.name ?? "",
                          imageURL: imageURL,
                          universalLinkBase: universalLinkBase,
                          deepLinkBase: deepLinkBase)
        }.sorted {
            $1.name > $0.name
        }
        
        return wcWallets
    }
    
    
    /// Start listening for incoming connections from wallets
    public func startListening() {
        
        if !isListening {
            isListening = true
            openNewConnection()
        }

    }
    
    /// Stops listening for incoming connections from wallets, disconnects currently connected sessions
    public func stopListening() {
        
        if isListening {
            isListening = false
            pendingSessionURISubject.send(nil)
        }
        
    }
    
    //Returns the URI string we are listening on for new connections
    @discardableResult
    func openNewConnection() -> String {
        //Can only fail when next URI collides with an existing one
        //Theoretically near impossible. Booth the 32 byte key and the UUID had to match for this to happen
        do {
            try client.connect(to: nextURL)
            pendingSession = PendingSession(url: nextURL,
                                            wallet: nil)
            
            pendingSessionURISubject.send(nextURL.absoluteString)
            
            let pendingURL = nextURL
            nextURL = Self.getNewURL()
            return pendingURL.absoluteString
        } catch let error {
            print("Congrats! You won the lottery with error:\n\(error)\nRetrying again...")
            return openNewConnection()
        }
    }
    
    /// Used for connecting to a ***wallet app***.
    /// If the wallet is installed, it will be opened with a connection request prompt.
    /// If the wallet is not installed, it will launch the AppStore where the user can download it.
    /// - Parameter wallet: The selected wallet you want to connect with
    ///
    /// - Warning: This method should only be called from the **main thread**.
    ///
    /// When a wallet in the WalletConnect registry does not have an associated *universal link*, and only provides a *deep link*, and the user does not have the selected wallet installed, this method will do nothing
    public func connect(withWallet wallet: Wallet) throws {
        
        guard isListening else { throw KycDaoError.genericError }

        try openWallet(wallet)
    }
    
    func openWallet(_ wallet: Wallet) throws {
        guard let connectionURL = pendingSession?.url.absoluteString
        else {
            throw KycDaoError.genericError
        }
        
        #warning("""
            MetaMask's WalletConnect universal links are broken since months.
            Remove this and use universal links when they fixed it.
        """)
        
        if wallet.name.lowercased() == "metamask" {
            try connectTo(wallet: wallet, connectionURL: connectionURL, tryDeepLinkFirst: true)
        } else {
            try connectTo(wallet: wallet, connectionURL: connectionURL)
        }
    }
    
    private func connectTo(wallet: Wallet, connectionURL: String, tryDeepLinkFirst: Bool = false) throws {
        
        var baseURL = wallet.universalLinkBase ?? wallet.deepLinkBase
        
        if tryDeepLinkFirst {
            baseURL = wallet.deepLinkBase ?? wallet.universalLinkBase
        }
        
        guard let baseURL else { throw KycDaoError.genericError }
        
        if let url = URL(string: "\(baseURL)?uri=\(connectionURL)") {
            UIApplication.shared.open(url)
            pendingSession?.wallet = wallet
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
                        continuation.resume(throwing: KycDaoError.walletConnect(.signingError(error.localizedDescription)))
                    }
                }
            } catch let error {
                continuation.resume(throwing: KycDaoError.walletConnect(.signingError(error.localizedDescription)))
            }
        }
    }
    
    func sign(account: String, message: String, wallet: Wallet) async throws -> String {
        
        let session = sessionRepo.getSession(walletId: wallet.id)
        guard let url = session?.url else { throw KycDaoError.genericError }
        
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
                        continuation.resume(throwing: KycDaoError.walletConnect(.signingError(error.localizedDescription)))
                    }
                }
                
                // safe to use deep link first as connecting with an universal link prooved that the user already installed the app
                guard let link = wallet.deepLinkBase ?? wallet.universalLinkBase,
                      let linkURL = URL(string: "\(link)") else {
                    throw KycDaoError.genericError
                }
                
                Task { @MainActor in
                    UIApplication.shared.open(linkURL)
                }
            } catch let error {
                continuation.resume(throwing: KycDaoError.walletConnect(.signingError(error.localizedDescription)))
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
                        continuation.resume(throwing: KycDaoError.walletConnect(.signingError(error.localizedDescription)))
                    }
                }
            } catch let error {
                continuation.resume(throwing: KycDaoError.walletConnect(.signingError(error.localizedDescription)))
            }
        }
    }
    
    func sendTransaction(transaction: Client.Transaction, wallet: Wallet) async throws -> String {
        
        let session = sessionRepo.getSession(walletId: wallet.id)
        guard let url = session?.url else { throw KycDaoError.genericError }
        
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
                        continuation.resume(throwing: KycDaoError.walletConnect(.signingError(error.localizedDescription)))
                    }
                }
                
                // safe to use deep link first as connecting with an universal link prooved that the user already installed the app
                guard let link = wallet.deepLinkBase ?? wallet.universalLinkBase,
                      let linkURL = URL(string: "\(link)") else {
                    throw KycDaoError.genericError
                }
                
                Task { @MainActor in
                    UIApplication.shared.open(linkURL)
                }
            } catch let error {
                continuation.resume(throwing: KycDaoError.walletConnect(.signingError(error.localizedDescription)))
            }
        }
    }
    
    private static func getNewURL() -> WCURL {
        WCURL(topic: UUID().uuidString,
              bridgeURL: URL(string: "https://safe-walletconnect.safe.global/")!,
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
            sessionStartedSubject.send(.failure(.failedToConnect(wallet: pendingSession.wallet)))
            openNewConnection()
        }
    }
    
    public func client(_ client: Client, didConnect url: WCURL) {
        print("didConnect wculr \(url)")
    }
    
    public func client(_ client: Client, didConnect session: WalletConnectSwift.Session) {
        print("didConnect session \(session.url)")
        print("session: \(session)")
        
        let newSessionSameAsPending = pendingSession?.url == session.url
                                      && !sessionRepo.containsSession(withURL: session.url)
        
        if let pendingSession = pendingSession, newSessionSameAsPending {
            
            let walletSession = try? WalletConnectSession(session: session,
                                                          wallet: pendingSession.wallet)
            
            guard let walletSession = walletSession else { return }
            
            sessionRepo.addSession(walletSession)
            sessionStartedSubject.send(.success(walletSession))
            openNewConnection()
        }
    }
    
    public func client(_ client: Client, didDisconnect session: WalletConnectSwift.Session) {
        print("didDisconnect \(session.url)")
        sessionRepo.deleteSession(session)
    }
    
    public func client(_ client: Client, didUpdate session: WalletConnectSwift.Session) {
        print("didUpdate \(session.url)")
        sessionRepo.updateSession(session)
    }
    
}
