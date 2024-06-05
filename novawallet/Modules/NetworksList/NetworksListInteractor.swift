import UIKit
import RobinHood
import SubstrateSdk
import SoraKeystore

final class NetworksListInteractor {
    weak var presenter: NetworksListInteractorOutputProtocol?

    let chainRegistry: ChainRegistryProtocol
    let settingsManager: SettingsManagerProtocol

    private var chains: [ChainModel.Id: ChainModel] = [:]

    init(
        chainRegistry: ChainRegistryProtocol,
        settingsManager: SettingsManagerProtocol
    ) {
        self.chainRegistry = chainRegistry
        self.settingsManager = settingsManager
    }

    private func subscribeChains() {
        chainRegistry.chainsSubscribe(
            self,
            runningInQueue: .main
        ) { [weak self] changes in
            guard let self else { return }
            presenter?.didReceiveChains(changes: changes)

            chains = changes.mergeToDict(chains)
            chains.keys.forEach { self.chainRegistry.subscribeChainState(self, chainId: $0) }
        }
    }
}

extension NetworksListInteractor: NetworksListInteractorInputProtocol {
    func provideChains() {
        subscribeChains()
    }

    func setIntegrationBannerSeen() {
        settingsManager.integrateNetworksBannerSeen = true
    }
}

extension NetworksListInteractor: ConnectionStateSubscription {
    func didReceive(
        state: WebSocketEngine.State,
        for chainId: ChainModel.Id
    ) {
        let connectionState: NetworksListPresenter.ConnectionState = switch state {
        case .notConnected, .connecting, .waitingReconnection:
            .connecting
        case .connected:
            .connected
        }

        presenter?.didReceive(connectionState: connectionState, for: chainId)
    }
}
