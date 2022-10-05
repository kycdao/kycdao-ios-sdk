//
//  EthereumTransactionReceipt.swift
//  
//
//  Created by Vekety Robin on 2022. 08. 11..
//

import Foundation
import web3

extension EthereumTransactionReceipt {
    
    //Modified from EthereumClient+Static.swift
    
    struct EthEvents {
        let events: [ABIEvent]
        let logs: [EthereumLog]
    }
    
    func lookForEvent<Event: ABIEvent>(event: Event.Type) -> Event? {
        let result = lookForEvents([event])
        return result.events.first(where: { $0 is Event }) as? Event
    }
    
    func lookForEvents(_ eventTypes: [ABIEvent.Type]) -> EthEvents {
        
        let typeFilters = eventTypes.map { EventFilter(type: $0, allowedSenders: []) }
        
        var events: [ABIEvent] = []
        var unprocessed: [EthereumLog] = []

        var filtersBySignature: [String: [EventFilter]] = [:]
        for filter in typeFilters {
            if let sig = try? filter.type.signature() {
                var filters = filtersBySignature[sig, default: [EventFilter]()]
                filters.append(filter)
                filtersBySignature[sig] = filters
            }
        }

        let parseEvent: (EthereumLog, ABIEvent.Type) -> ABIEvent? = { log, eventType in
            let topicTypes = eventType.types.enumerated()
                .filter { eventType.typesIndexed[$0.offset] == true }
                .compactMap { $0.element }

            let dataTypes = eventType.types.enumerated()
                .filter { eventType.typesIndexed[$0.offset] == false }
                .compactMap { $0.element }

            guard let data = try? ABIDecoder.decodeData(log.data, types: dataTypes, asArray: true) else {
                return nil
            }

            guard data.count == dataTypes.count else {
                return nil
            }

            let rawTopics = Array(log.topics.dropFirst())

            guard let parsedTopics = (try? zip(rawTopics, topicTypes).map { pair in
                try ABIDecoder.decodeData(pair.0, types: [pair.1])
            }) else {
                return nil
            }

            guard let eventOpt = ((try? eventType.init(topics: parsedTopics.flatMap { $0 }, data: data, log: log)) as ABIEvent??), let event = eventOpt else {
                return nil
            }

            return event
        }

        for log in logs {
            guard let signature = log.topics.first,
                  let filters = filtersBySignature[signature] else {
                unprocessed.append(log)
                continue
            }

            for filter in filters {
                let allowedSenders = Set(filter.allowedSenders)
                if allowedSenders.count > 0 && !allowedSenders.contains(log.address) {
                    unprocessed.append(log)
                } else if let event = parseEvent(log, filter.type) {
                    events.append(event)
                } else {
                    unprocessed.append(log)
                }
            }
        }
    
        return EthEvents(events: events, logs: unprocessed)
        
    }
    
}
