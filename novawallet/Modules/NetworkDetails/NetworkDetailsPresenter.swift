import SoraFoundation

final class NetworkDetailsPresenter {
    weak var view: NetworkDetailsViewProtocol?
    let wireframe: NetworkDetailsWireframeProtocol
    let interactor: NetworkDetailsInteractorInputProtocol

    private var chain: ChainModel
    private var sortedNodes: [ChainNodeModel] = []
    private var connectionStates: [String: ConnectionState] = [:]
    private var nodes: [String: ChainNodeModel] = [:]
    private var nodesIndexes: [String: Int] = [:]

    private let viewModelFactory: NetworkDetailsViewModelFactory

    init(
        interactor: NetworkDetailsInteractorInputProtocol,
        wireframe: NetworkDetailsWireframeProtocol,
        chain: ChainModel,
        viewModelFactory: NetworkDetailsViewModelFactory
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.chain = chain
        self.viewModelFactory = viewModelFactory

        sortedNodes = chain.nodes.sorted { $0.order < $1.order }
    }
}

// MARK: NetworkDetailsPresenterProtocol

extension NetworkDetailsPresenter: NetworkDetailsPresenterProtocol {
    func setup() {
        interactor.setup()

        indexNodes()
        provideViewModel()
    }

    func toggleEnabled() {
        interactor.toggleNetwork()
    }

    func toggleConnectionMode() {
        interactor.toggleConnectionMode()
    }

    func addNode() {
        // TODO: Implement
    }

    func selectNode(at index: Int) {
        let node = sortedNodes[index]
        interactor.selectNode(node)
    }
}

// MARK: NetworkDetailsInteractorOutputProtocol

extension NetworkDetailsPresenter: NetworkDetailsInteractorOutputProtocol {
    func didReceive(updatedChain: ChainModel) {
        chain = updatedChain
        sortedNodes = chain.nodes.sorted { $0.order < $1.order }

        indexNodes()
        provideViewModel()
    }

    func didReceive(
        _ connectionState: ConnectionState,
        for nodeURL: String
    ) {
        guard connectionState != connectionStates[nodeURL] else { return }

        connectionStates[nodeURL] = connectionState

        switch connectionState {
        case .connecting, .disconnected, .pinged:
            provideNodeViewModel(for: nodeURL)
        case .connected:
            print(connectionState)
        }
    }
}

// MARK: Private

private extension NetworkDetailsPresenter {
    func provideViewModel() {
        let viewModel = viewModelFactory.createViewModel(
            for: chain,
            nodes: sortedNodes,
            nodesIndexes: nodesIndexes,
            connectionStates: connectionStates
        )
        view?.update(with: viewModel)
    }

    func provideNodeViewModel(for url: String) {
        guard
            let node = nodes[url],
            nodesIndexes[url] != nil
        else {
            return
        }

        let viewModel = viewModelFactory.createNodesSection(
            with: [node],
            chain: chain,
            nodesIndexes: nodesIndexes,
            connectionStates: connectionStates
        )

        view?.updateNodes(with: viewModel)
    }

    func indexNodes() {
        nodesIndexes = [:]
        nodes = [:]

        sortedNodes.enumerated().forEach { index, node in
            nodesIndexes[node.url] = index
            nodes[node.url] = node
        }
    }
}

extension NetworkDetailsPresenter {
    enum ConnectionState: Equatable {
        case connecting
        case connected
        case disconnected
        case pinged(Int)

        static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
            switch (lhs, rhs) {
            case (.connecting, .connecting):
                true
            case (.connected, .connected):
                true
            case (.disconnected, .disconnected):
                true
            case let (.pinged(lhsPing), .pinged(rhsPing)):
                lhsPing == rhsPing
            default:
                false
            }
        }
    }
}
