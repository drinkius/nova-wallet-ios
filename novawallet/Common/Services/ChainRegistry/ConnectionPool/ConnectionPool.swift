import Foundation
import SubstrateSdk
import SoraFoundation

protocol ConnectionPoolProtocol {
    func setupConnection(for chain: ChainModel) throws -> ChainConnection
    func clearConnection(for chainId: ChainModel.Id)
    func getConnection(for chainId: ChainModel.Id) -> ChainConnection?
    func subscribe(_ subscriber: ConnectionStateSubscription, chainId: ChainModel.Id)
    func unsubscribe(_ subscriber: ConnectionStateSubscription, chainId: ChainModel.Id)
    func getOneShotConnection(for chain: ChainModel) -> JSONRPCEngine?
    func deactivateConnection(for chainId: ChainModel.Id)
}

protocol ConnectionStateSubscription: AnyObject {
    func didReceive(state: WebSocketEngine.State, for chainId: ChainModel.Id)
}

class ConnectionPool {
    let connectionFactory: ConnectionFactoryProtocol
    let applicationHandler: ApplicationHandlerProtocol

    private var mutex = NSLock()

    private(set) var connections: [ChainModel.Id: ChainConnection] = [:]
    private(set) var oneShotConnections: [ChainModel.Id: OneShotConnection] = [:]

    private(set) var stateSubscriptions: [ChainModel.Id: [WeakWrapper]] = [:]

    init(connectionFactory: ConnectionFactoryProtocol, applicationHandler: ApplicationHandlerProtocol) {
        self.connectionFactory = connectionFactory
        self.applicationHandler = applicationHandler

        applicationHandler.delegate = self
    }
}

extension ConnectionPool: ConnectionPoolProtocol {
    func subscribe(_ subscriber: ConnectionStateSubscription, chainId: ChainModel.Id) {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        if let subscribers = stateSubscriptions[chainId], subscribers.contains(where: { $0.target === subscriber }) {
            return
        }

        var subscribers = stateSubscriptions[chainId] ?? []
        subscribers.append(WeakWrapper(target: subscriber))
        stateSubscriptions[chainId] = subscribers

        let connection = connections[chainId]

        DispatchQueue.main.async {
            subscriber.didReceive(state: connection?.state ?? .notConnected(url: nil), for: chainId)
        }
    }

    func unsubscribe(_ subscriber: ConnectionStateSubscription, chainId: ChainModel.Id) {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        let subscribers = stateSubscriptions[chainId]
        stateSubscriptions[chainId] = subscribers?.filter { $0.target !== subscriber }
    }

    func setupConnection(for chain: ChainModel) throws -> ChainConnection {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        if let connection = connections[chain.chainId] {
            connectionFactory.updateConnection(connection, chain: chain)
            return connection
        }

        let connection = try connectionFactory.createConnection(for: chain, delegate: self)
        connections[chain.chainId] = connection

        return connection
    }

    func clearConnection(for chainId: ChainModel.Id) {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        if let connection = connections[chainId] {
            connection.disconnect(true)
            connections[chainId] = nil
        }
    }

    func deactivateConnection(for chainId: ChainModel.Id) {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        oneShotConnections[chainId] = nil

        if let connection = connections[chainId] {
            connection.disconnect(true)
        }
    }

    func getConnection(for chainId: ChainModel.Id) -> ChainConnection? {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        return connections[chainId]
    }

    func getOneShotConnection(for chain: ChainModel) -> JSONRPCEngine? {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        if let existingConnection = oneShotConnections[chain.chainId] {
            connectionFactory.updateOneShotConnection(existingConnection, chain: chain)

            return existingConnection
        }

        if let connection = try? connectionFactory.createOneShotConnection(for: chain) {
            oneShotConnections[chain.chainId] = connection

            return connection
        } else {
            return connections[chain.chainId] as? JSONRPCEngine
        }
    }
}

extension ConnectionPool: WebSocketEngineDelegate {
    func webSocketDidSwitchURL(_: AnyObject, newUrl _: URL) {}

    func webSocketDidChangeState(
        _ connection: AnyObject,
        from _: WebSocketEngine.State,
        to newState: WebSocketEngine.State
    ) {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        let allChainIds = connections.keys
        let maybeChainId = allChainIds.first(where: { connections[$0] === connection })

        guard let chainId = maybeChainId else {
            return
        }

        let maybeSubscriptions = stateSubscriptions[chainId]?.compactMap { $0.target as? ConnectionStateSubscription }

        guard let subscriptions = maybeSubscriptions, !subscriptions.isEmpty else {
            return
        }

        DispatchQueue.main.async {
            subscriptions.forEach { $0.didReceive(state: newState, for: chainId) }
        }
    }
}

extension ConnectionPool: ApplicationHandlerDelegate {
    func didReceiveDidBecomeActive(notification _: Notification) {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        connections.values.forEach { $0.connect() }
    }

    func didReceiveDidEnterBackground(notification _: Notification) {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        connections.values.forEach { $0.disconnect(true) }
    }
}
