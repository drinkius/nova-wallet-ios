import SoraFoundation

final class NetworkDetailsPresenter {
    weak var view: NetworkDetailsViewProtocol?
    let wireframe: NetworkDetailsWireframeProtocol
    let interactor: NetworkDetailsInteractorInputProtocol

    private var chain: ChainModel
    private var sortedNodes: [ChainNodeModel] = []
    private var connectionStates: [String: ConnectionState] = [:]
    private var nodesIds: [String: UUID] = [:]
    private var nodes: [UUID: ChainNodeModel] = [:]
    private var selectedNode: ChainNodeModel?

    private let viewModelFactory: NetworkDetailsViewModelFactory

    init(
        interactor: NetworkDetailsInteractorInputProtocol,
        wireframe: NetworkDetailsWireframeProtocol,
        chain: ChainModel,
        viewModelFactory: NetworkDetailsViewModelFactory,
        localizationManager: LocalizationManagerProtocol
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.chain = chain
        self.viewModelFactory = viewModelFactory
        self.localizationManager = localizationManager
    }
}

// MARK: NetworkDetailsPresenterProtocol

extension NetworkDetailsPresenter: NetworkDetailsPresenterProtocol {
    func setup() {
        interactor.setup()
    }

    func setNetwork(enabled: Bool) {
        interactor.setSetNetworkConnection(enabled: enabled)
    }

    func setAutoBalance(enabled: Bool) {
        interactor.setAutoBalance(enabled: enabled)
    }

    func addNode() {
        wireframe.showAddNode(
            from: view,
            chainId: chain.chainId
        )
    }

    func selectNode(with id: UUID) {
        guard let node = nodes[id] else {
            return
        }
        
        interactor.selectNode(node)
    }
    
    func manageNetwork() {
        openManageNetwork()
    }
}

// MARK: NetworkDetailsInteractorOutputProtocol

extension NetworkDetailsPresenter: NetworkDetailsInteractorOutputProtocol {
    func didReceive(
        _ chain: ChainModel,
        filteredNodes: Set<ChainNodeModel>
    ) {
        self.chain = chain

        sortedNodes = filteredNodes.sorted { $0.order < $1.order }

        if sortedNodes.count == 1, let selectedNode = sortedNodes.first {
            self.selectedNode = selectedNode
        } else if case let .manual(selectedNode) = chain.connectionMode {
            self.selectedNode = selectedNode
        }

        indexNodes(sortedNodes)
        provideViewModel()
    }

    func didReceive(
        _ connectionState: ConnectionState,
        for nodeURL: String,
        selected: Bool
    ) {
        guard
            connectionState != connectionStates[nodeURL],
            let nodeId = nodesIds[nodeURL],
            let node = nodes[nodeId]
        else {
            return
        }
        
        if selected {
            selectedNode = node
        } else if selectedNode?.url == nodeURL {
            selectedNode = nil
        }

        connectionStates[nodeURL] = connectionState

        switch connectionState {
        case .connecting, .disconnected, .pinged, .unknown:
            provideNodeViewModel(for: node)
        case .connected:
            break
        }
    }
    
    func didReceive(_ error: any Error) {
        wireframe.present(
            error: error,
            from: view,
            locale: selectedLocale
        )
    }
}

// MARK: Private

private extension NetworkDetailsPresenter {
    func provideViewModel() {
        let viewModel = viewModelFactory.createViewModel(
            for: chain,
            nodes: sortedNodes,
            selectedNode: selectedNode,
            nodesIds: nodesIds,
            connectionStates: connectionStates,
            onTapMore: editNode(with:)
        )
        view?.update(with: viewModel)
    }

    func provideNodeViewModel(for node: ChainNodeModel) {
        let viewModel = switch node.source {
        case .user:
            viewModelFactory.createAddNodeSection(
                with: [node],
                selectedNode: selectedNode,
                chain: chain,
                nodesIds: nodesIds,
                connectionStates: connectionStates,
                onTapMore: editNode(with:)
            )
        case .remote:
            viewModelFactory.createNodesSection(
                with: [node],
                selectedNode: selectedNode,
                chain: chain,
                nodesIds: nodesIds,
                connectionStates: connectionStates
            )
        }

        view?.updateNodes(with: viewModel)
    }

    func indexNodes(_ sortedNodes: [ChainNodeModel]) {
        nodes = [:]
        
        sortedNodes.forEach { node in
            if nodesIds[node.url] == nil {
                nodesIds[node.url] = UUID()
            }
            
            let id = nodesIds[node.url]!
            
            nodes[id] = node
        }
    }
    
    func editNode(with id: UUID) {
        guard let node = nodes[id] else { return }
        
        wireframe.showManageNode(
            from: view,
            node: node,
            onNodeEdit: { [weak self] in
                guard let self else { return }
                
                wireframe.showEditNode(
                    from: view,
                    node: node,
                    chainId: chain.chainId
                )
            },
            onNodeDelete: { [weak self] in
                self?.interactor.deleteNode(node)
            }
        )
    }
    
    func openManageNetwork() {
        guard let view else {
            return
        }

        let actionViewModels: [LocalizableResource<ActionManageViewModel>] = [
            LocalizableResource { locale in
                ActionManageViewModel(
                    icon: R.image.iconPencil()?
                        .tinted(with: R.color.colorIconPrimary()!)?
                        .withRenderingMode(.alwaysOriginal),
                    title: R.string.localizable.networkManageEdit(preferredLanguages: locale.rLanguages)
                )
            },
            LocalizableResource { locale in
                ActionManageViewModel(
                    icon: R.image.iconDelete(),
                    title: R.string.localizable.networkManageDelete(preferredLanguages: locale.rLanguages),
                    isDestructive: true
                )
            }
        ]

        let context = ModalPickerClosureContext { [weak self] index in
            guard 
                let self,
                let manageAction = ManageActions(rawValue: index)
            else {
                return
            }

            switch manageAction {
            case .edit:
                guard let selectedNode else { return }
                
                wireframe.showEditNetwork(
                    from: view,
                    network: chain,
                    selectedNode: selectedNode
                )
            case .delete:
                print("DELETE")
            }
        }

        wireframe.presentActionsManage(
            from: view,
            actions: actionViewModels,
            title: LocalizableResource { locale in
                R.string.localizable.commonManageBackup(preferredLanguages: locale.rLanguages)
            },
            delegate: self,
            context: context
        )
    }
}

// MARK: ModalPickerViewControllerDelegate

extension NetworkDetailsPresenter: ModalPickerViewControllerDelegate {
    func modalPickerDidSelectModelAtIndex(_ index: Int, context: AnyObject?) {
        guard let context = context as? ModalPickerClosureContext else {
            return
        }
        
        context.process(selectedIndex: index)
    }
}

// MARK: Localizable

extension NetworkDetailsPresenter: Localizable {
    func applyLocalization() {
        guard let view, view.isSetup else {
            return
        }
        
        provideViewModel()
    }
}

extension NetworkDetailsPresenter {
    enum ConnectionState: Equatable {
        case connecting
        case connected
        case disconnected
        case pinged(Int)
        case unknown
    }
}

private extension NetworkDetailsPresenter {
    enum ManageActions: Int {
        case edit = 0
        case delete
    }
}
