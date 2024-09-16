protocol SwipeGovReferendumDetailsViewProtocol: ControllerBackedProtocol {
    func didReceive(titleModel: ReferendumDetailsTitleView.Model)
    func didReceive(trackTagsModel: TrackTagsView.Model?)
    func didReceive(activeTimeViewModel: ReferendumInfoView.Time?)
}

protocol SwipeGovReferendumDetailsPresenterProtocol: AnyObject {
    func setup()
    func showProposerDetails()
}

protocol SwipeGovReferendumDetailsInteractorInputProtocol: AnyObject {
    func setup()
    func refreshBlockTime()
    func refreshActionDetails()
    func refreshIdentities(for accountIds: Set<AccountId>)
    func remakeSubscriptions()
}

protocol SwipeGovReferendumDetailsInteractorOutputProtocol: AnyObject {
    func didReceiveReferendum(_ referendum: ReferendumLocal)
    func didReceiveIdentities(_ identities: [AccountAddress: AccountIdentity])
    func didReceiveBlockNumber(_ blockNumber: BlockNumber)
    func didReceiveBlockTime(_ blockTime: BlockTime)
    func didReceiveActionDetails(_ actionDetails: ReferendumActionLocal)
    func didReceiveError(_ error: ReferendumDetailsInteractorError)
}

protocol SwipeGovReferendumDetailsWireframeProtocol: AlertPresentable, ErrorPresentable, CommonRetryable,
                                                     AddressOptionsPresentable, WebPresentable, NoAccountSupportPresentable {
    
}
