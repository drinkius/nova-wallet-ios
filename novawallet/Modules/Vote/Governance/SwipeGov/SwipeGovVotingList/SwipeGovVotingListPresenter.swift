import Foundation
import SoraFoundation

final class SwipeGovVotingListPresenter {
    weak var view: SwipeGovVotingListViewProtocol?

    private let wireframe: SwipeGovVotingListWireframeProtocol
    private let interactor: SwipeGovVotingListInteractorInputProtocol
    private let localizationManager: LocalizationManagerProtocol
    private let chain: ChainModel

    private let viewModelFactory: SwipeGovVotingListViewModelFactory

    private var votingListItems: [VotingBasketItemLocal] = []

    init(
        interactor: SwipeGovVotingListInteractorInputProtocol,
        wireframe: SwipeGovVotingListWireframeProtocol,
        chain: ChainModel,
        viewModelFactory: SwipeGovVotingListViewModelFactory,
        localizationManager: LocalizationManagerProtocol
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.chain = chain
        self.viewModelFactory = viewModelFactory
        self.localizationManager = localizationManager
    }
}

// MARK: SwipeGovVotingListPresenterProtocol

extension SwipeGovVotingListPresenter: SwipeGovVotingListPresenterProtocol {
    func setup() {
        interactor.setup()
    }

    func removeItem(with referendumId: ReferendumIdLocal) {
        print(referendumId)
    }

    func selectVoting(for referendumId: ReferendumIdLocal) {
        print(referendumId)
    }
}

// MARK: SwipeGovVotingListInteractorOutputProtocol

extension SwipeGovVotingListPresenter: SwipeGovVotingListInteractorOutputProtocol {
    func didReceive(_ votingBasketItems: [VotingBasketItemLocal]) {
        votingListItems = votingBasketItems
        updateView()
    }

    func didReceive(_ error: Error) {
        print(error)
    }
}

// MARK: Private

private extension SwipeGovVotingListPresenter {
    func updateView() {
        let viewModel = viewModelFactory.createListViewModel(
            using: votingListItems,
            chain: chain,
            locale: localizationManager.selectedLocale
        )

        view?.didReceive(viewModel)
    }
}
