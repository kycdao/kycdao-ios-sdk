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
    
    static var shared = SessionRepository()
    var sessions: [WalletSession] = []
    
    func containsSession(withURL url: WCURL) -> Bool {
        sessions.contains(where: { $0.url == url })
    }
    
    func updateSession(_ session: WCSession) {
        let savedSession = sessions.first(where: { $0.url == session.url })
        try? savedSession?.updateSession(session)
    }
    
    func deleteSession(_ session: WCSession) {
        sessions.removeAll(where: { $0.url == session.url })
    }
    
    func addSession(_ session: WalletSession) {
        sessions.removeAll(where: { $0.url == session.url })
        sessions.append(session)
    }
    
    func getSession(walletId: String) -> WalletSession? {
        sessions
            .first(where: { $0.walletId == walletId })
    }
    
    func getWCSession(walletId: String) -> WCSession? {
        getSession(walletId: walletId).map(\.wcSession)
    }
    
}
