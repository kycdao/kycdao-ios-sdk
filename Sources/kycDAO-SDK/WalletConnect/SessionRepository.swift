//
//  SessionRepository.swift
//  
//
//  Created by Vekety Robin on 2022. 06. 28..
//

import Foundation
import Combine
import WalletConnectSwift

class SessionRepository {
    
    private static let wcSessionKey = "kyc.wcSessionKey"
    
    static var shared = SessionRepository()
    
    private var disposeBag = Set<AnyCancellable>()
    
    @Published
    var sessions: [WalletSession]
    
    var sessionUpdates = PassthroughSubject<WalletSession, Never>()
    
    internal var wcSessions: [WCSession] {
        sessions.map(\.wcSession)
    }
    
    private init() {
        if let savedSessionsData = UserDefaults.standard.object(forKey: Self.wcSessionKey) as? Data {
            let savedSessions = (try? JSONDecoder().decode([WalletSession].self, from: savedSessionsData)) ?? []
            sessions = savedSessions.map { savedSession in
                var session = savedSession
                session.status = .inactive
                return session
            }
        } else {
            sessions = []
        }
        
        $sessions.sink { savedSessions in
            guard let sessionsData = try? JSONEncoder().encode(savedSessions) else { return }
            UserDefaults.standard.set(sessionsData, forKey: Self.wcSessionKey)
        }.store(in: &disposeBag)
    }
    
    func sessions(forConnectionState state: ConnectionState) -> AnyPublisher<[WalletSession], Never> {
        $sessions.map { savedSessions in
            savedSessions.filter { $0.state == state }
        }.eraseToAnyPublisher()
    }
    
    func sessions(forStatus status: SessionStatus) -> AnyPublisher<[WalletSession], Never> {
        $sessions.map { savedSessions in
            savedSessions.filter { $0.status == status }
        }.eraseToAnyPublisher()
    }
    
    func saveSession(_ newSession: WalletSession) {
        addSession(newSession)
    }
    
    func saveSession(_ newSession: WCSession, status: SessionStatus? = nil, state: ConnectionState? = nil, wallet: Wallet? = nil) {
        
        let savedStatus = sessions.first(where: { $0.url == newSession.url })?.status ?? .inactive
        let savedState = sessions.first(where: { $0.url == newSession.url })?.state ?? .initialised
        
        if wallet == nil,
           let savedMatchingSession = sessions.first(where: { $0.url == newSession.url }) {
            
            let previousWallet = savedMatchingSession.wallet
            let session = try? WalletSession(session: newSession,
                                             wallet: previousWallet,
                                             status: status ?? savedStatus,
                                             state: state ?? savedState)
            guard let session = session else { return }
            addSession(session)
            
        } else {
            
            let session = try? WalletSession(session: newSession,
                                             wallet: wallet,
                                             status: status ?? savedStatus,
                                             state: state ?? savedState)
            guard let session = session else { return }
            addSession(session)
        }
        
    }
    
    func deleteSession(_ session: WCSession) {
        sessions.removeAll(where: { $0.url == session.url })
    }
    
    func containsSession(withURL url: WCURL) -> Bool {
        sessions.contains(where: { $0.url == url })
    }
    
    func getSession(walletId: String) -> WCSession? {
        sessions.first(where: { $0.walletId == walletId })
            .map(\.wcSession)
    }
    
    func getSession(url: WCURL) -> WalletSession? {
        sessions.first(where: { $0.url == url })
    }
    
    func setStatus(_ status: SessionStatus, forSessionWithURL url: WCURL) {
        
        if let session = sessions.first(where: { $0.url == url }) {
            var sessionCopy = session
            sessionCopy.status = status
            addSession(sessionCopy)
        }
        
    }
    
    func setState(_ state: ConnectionState, forSessionWithURL url: WCURL) {
        
        if let session = sessions.first(where: { $0.url == url }) {
            var sessionCopy = session
            sessionCopy.state = state
            addSession(sessionCopy)
        }
        
    }
    
    private func addSession(_ session: WalletSession) {
        sessions.removeAll(where: { $0.url == session.url })
        sessions.append(session)
        sessionUpdates.send(session)
    }
    
    func stateOfSession(forURL url: WCURL) -> ConnectionState? {
        getSession(url: url)?.state
    }
    
}
