import Foundation
import RobinHood
import SoraFoundation

final class NetworksListPresenter {
    weak var view: NetworksListViewProtocol?
    let wireframe: NetworksListWireframeProtocol
    let interactor: NetworksListInteractorInputProtocol

    private var chains: [ChainModel.Id: ChainModel] = [:]
    private var connectionStates: [ChainModel.Id: ConnectionState] = [:]
    private var chainIndexes: [ChainModel.Id: Int] = [:]

    private var selectedNetworksType: NetworksType? = .default
    private var sortedChains: SortedChains?

    private let viewModelFactory: NetworksListViewModelFactory

    init(
        interactor: NetworksListInteractorInputProtocol,
        wireframe: NetworksListWireframeProtocol,
        viewModelFactory: NetworksListViewModelFactory
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.viewModelFactory = viewModelFactory
    }
}

// MARK: NetworksListPresenterProtocol

extension NetworksListPresenter: NetworksListPresenterProtocol {
    func selectChain(at _: Int) {}

    func select(segment: NetworksType?) {
        selectedNetworksType = segment
        indexChains()
        provideViewModels()
    }

    func setup() {
        interactor.provideChains()
    }

    func addNetwork() {
        // TODO: Implement routing
    }
}

// MARK: NetworksListInteractorOutputProtocol

extension NetworksListPresenter: NetworksListInteractorOutputProtocol {
    func didReceiveChains(changes: [DataProviderChange<ChainModel>]) {
        chains = changes.mergeToDict(chains)
        sortedChains = sorted(chains: chains)

        indexChains()

        provideViewModels()
    }

    func didReceive(
        connectionState: ConnectionState,
        for chainId: ChainModel.Id
    ) {
        connectionStates[chainId] = connectionState
        provideNetworkViewModel(for: chainId)
    }
}

// MARK: Private

private extension NetworksListPresenter {
    func provideViewModels() {
        guard
            let selectedNetworksType,
            let sortedChains
        else { return }

        let viewModel = switch selectedNetworksType {
        case .default:
            viewModelFactory.createDefaultViewModel(
                for: sortedChains.defaultChains,
                indexes: chainIndexes,
                with: connectionStates
            )
        case .added:
            viewModelFactory.createAddedViewModel(
                for: sortedChains.addedChains,
                indexes: chainIndexes,
                with: connectionStates
            )
        }

        view?.update(with: viewModel)
    }

    func provideNetworkViewModel(for chainId: ChainModel.Id) {
        guard
            let chain = chains[chainId],
            chainIndexes[chainId] != nil
        else {
            return
        }

        let viewModel = viewModelFactory.createDefaultViewModel(
            for: [chain],
            indexes: chainIndexes,
            with: connectionStates
        )

        view?.updateNetworks(with: viewModel)
    }

    func sorted(chains: [ChainModel.Id: ChainModel]) -> SortedChains {
        var defaultChains: [ChainModel] = []
        var addedChains: [ChainModel] = []

        chains.forEach { chain in
            if chain.value.source == .remote {
                defaultChains.append(chain.value)
            } else {
                addedChains.append(chain.value)
            }
        }

        defaultChains.sort { ChainModelCompator.defaultComparator(chain1: $0, chain2: $1) }
        addedChains.sort { ChainModelCompator.defaultComparator(chain1: $0, chain2: $1) }

        return SortedChains(
            defaultChains: defaultChains,
            addedChains: addedChains
        )
    }

    func indexChains() {
        guard let sortedChains else {
            return
        }

        chainIndexes = [:]

        let chainsToIndex = if selectedNetworksType == .default {
            sortedChains.defaultChains
        } else {
            sortedChains.addedChains
        }

        chainsToIndex.enumerated().forEach { index, chain in
            chainIndexes[chain.chainId] = index
        }
    }
}

extension NetworksListPresenter {
    enum ConnectionState {
        case connecting
        case connected
    }

    enum NetworksType: Int {
        case `default` = 0
        case added = 1
    }

    struct SortedChains {
        let defaultChains: [ChainModel]
        let addedChains: [ChainModel]
    }
}
