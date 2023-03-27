import Foundation
import RobinHood

protocol ReferendumsViewProtocol: ControllerBackedProtocol {
    var presenter: ReferendumsPresenterProtocol? { get set }

    func didReceiveChainBalance(viewModel: ChainBalanceViewModel)
    func update(model: ReferendumsViewModel)
    func updateReferendums(time: [UInt: StatusTimeViewModel?])
}

protocol ReferendumsPresenterProtocol: AnyObject {
    func select(referendumIndex: UInt)
    func selectUnlocks()
    func selectDelegations()
}

protocol ReferendumsInteractorInputProtocol: AnyObject {
    func setup()
    func saveSelected(option: GovernanceSelectedOption)
    func becomeOnline()
    func putOffline()
    func refresh()
    func refreshUnlockSchedule(for tracksVoting: ReferendumTracksVotingDistribution, blockHash: Data?)
    func remakeSubscriptions()
    func retryBlockTime()
    func retryOffchainVotingFetch()
}

protocol ReferendumsInteractorOutputProtocol: AnyObject {
    func didReceiveReferendums(_ referendums: [ReferendumLocal])
    func didReceiveReferendumsMetadata(_ changes: [DataProviderChange<ReferendumMetadataLocal>])
    func didReceiveVoting(_ voting: CallbackStorageSubscriptionResult<ReferendumTracksVotingDistribution>)
    func didReceiveOffchainVoting(_ voting: GovernanceOffchainVotesLocal)
    func didReceiveSelectedOption(_ option: GovernanceSelectedOption)
    func didReceiveAssetBalance(_ balance: AssetBalance?)
    func didReceivePrice(_ price: PriceData?)
    func didReceiveBlockNumber(_ blockNumber: BlockNumber)
    func didReceiveBlockTime(_ blockTime: BlockTime)
    func didReceiveUnlockSchedule(_ unlockSchedule: GovernanceUnlockSchedule)
    func didReceiveSupportDelegations(_ supportsDelegations: Bool)
    func didReceiveError(_ error: ReferendumsInteractorError)
}

protocol ReferendumsWireframeProtocol: AlertPresentable, ErrorPresentable, CommonRetryable {
    func selectChain(
        from view: ControllerBackedProtocol?,
        delegate: GovernanceAssetSelectionDelegate,
        chainId: ChainModel.Id?,
        governanceType: GovernanceType?
    )

    func showReferendumDetails(from view: ControllerBackedProtocol?, initData: ReferendumDetailsInitData)

    func showUnlocksDetails(from view: ControllerBackedProtocol?, initData: GovernanceUnlockInitData)

    func showAddDelegation(from view: ControllerBackedProtocol?)
    func showYourDelegations(from view: ControllerBackedProtocol?)
}
