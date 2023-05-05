protocol WalletConnectInteractorInputProtocol: AnyObject {}

protocol WalletConnectInteractorOutputProtocol: AnyObject {}

protocol WalletConnectDelegateInputProtocol: AnyObject {
    func connect(uri: String)

    func add(delegate: WalletConnectDelegateOutputProtocol)
    func remove(delegate: WalletConnectDelegateOutputProtocol)

    func getSessionsCount() -> Int

    func fetchSessions(_ completion: @escaping (Result<[WalletConnectSession], Error>) -> Void)

    func disconnect(from session: String, completion: @escaping (Error?) -> Void)
}

protocol WalletConnectDelegateOutputProtocol: AnyObject {
    func walletConnectDidChangeSessions()
}
