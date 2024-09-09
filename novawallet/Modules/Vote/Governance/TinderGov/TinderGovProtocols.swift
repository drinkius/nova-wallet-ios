protocol TinderGovViewProtocol: ControllerBackedProtocol {
    func updateCards(with newModels: [VoteCardViewModel])
    func updateVotingList(with viewModel: VotingListWidgetViewModel)
    func updateCardsCounter(with text: String)
}

protocol TinderGovPresenterProtocol: AnyObject {
    func setup()
    func actionBack()
}

protocol TinderGovInteractorInputProtocol: AnyObject {
    func setup()
}

protocol TinderGovInteractorOutputProtocol: AnyObject {
    func didReceive(_ referendums: [ReferendumLocal])
}

protocol TinderGovWireframeProtocol: AnyObject {
    func back(from view: ControllerBackedProtocol?)
}
