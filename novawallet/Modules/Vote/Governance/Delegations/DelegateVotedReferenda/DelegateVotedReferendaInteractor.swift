import UIKit
import RobinHood

final class DelegateVotedReferendaInteractor: AnyCancellableCleaning {
    weak var presenter: DelegateVotedReferendaInteractorOutputProtocol!

    let governanceState: GovernanceSharedState
    let chainRegistry: ChainRegistryProtocol
    let serviceFactory: GovernanceServiceFactoryProtocol
    let operationQueue: OperationQueue
    let address: AccountAddress
    let governanceOffchainVotingFactory: GovernanceOffchainVotingFactoryProtocol

    var generalLocalSubscriptionFactory: GeneralStorageSubscriptionFactoryProtocol {
        governanceState.generalLocalSubscriptionFactory
    }

    private(set) var blockNumberSubscription: AnyDataProvider<DecodedBlockNumber>?
    private(set) var metadataProvider: StreamableProvider<ReferendumMetadataLocal>?

    var referendumsCancellable: CancellableCall?
    var blockTimeCancellable: CancellableCall?
    var offchainVotingCancellable: CancellableCall?

    init(
        governanceState: GovernanceSharedState,
        chainRegistry: ChainRegistryProtocol,
        serviceFactory: GovernanceServiceFactoryProtocol,
        address: AccountAddress,
        governanceOffchainVotingFactory: GovernanceOffchainVotingFactoryProtocol,
        operationQueue: OperationQueue
    ) {
        self.governanceState = governanceState
        self.chainRegistry = chainRegistry
        self.serviceFactory = serviceFactory
        self.operationQueue = operationQueue
        self.address = address
        self.governanceOffchainVotingFactory = governanceOffchainVotingFactory
    }

    deinit {
        clearBlockTimeService()
        clearCancellable()
    }

    func clear() {
        clearBlockTimeService()
        clearSubscriptionFactory()
        clearBlockNumberSubscription()
        clearCancellable()
    }

    func clearCancellable() {
        clear(cancellable: &referendumsCancellable)
        clear(cancellable: &blockTimeCancellable)
        clear(cancellable: &offchainVotingCancellable)
    }

    private func clearBlockTimeService() {
        governanceState.blockTimeService?.throttle()
        governanceState.replaceBlockTimeService(nil)
    }

    private func clearSubscriptionFactory() {
        governanceState.replaceGovernanceFactory(for: nil)
    }

    func clearBlockNumberSubscription() {
        blockNumberSubscription?.removeObserver(self)
        blockNumberSubscription = nil
    }

    func continueSetup() {
        guard let option = governanceState.settings.value else {
            presenter?.didReceiveError(.settingsLoadFailed)
            return
        }

        setupBlockTimeService(for: option.chain)
        provideBlockTime()
        setupSubscriptionFactory(for: option)
        subscribeToBlockNumber(for: option.chain)
        subscribeToMetadata(for: option)
    }

    private func setupBlockTimeService(for chain: ChainModel) {
        do {
            let blockTimeService = try serviceFactory.createBlockTimeService(for: chain.chainId)
            governanceState.replaceBlockTimeService(blockTimeService)
            blockTimeService.setup()
        } catch {
            presenter?.didReceiveError(.blockTimeServiceFailed(error))
        }
    }

    private func setupSubscriptionFactory(for option: GovernanceSelectedOption) {
        governanceState.replaceGovernanceFactory(for: option)
    }

    func subscribeToBlockNumber(for chain: ChainModel) {
        guard blockNumberSubscription == nil else {
            return
        }

        blockNumberSubscription = subscribeToBlockNumber(for: chain.chainId)
    }

    private func subscribeToMetadata(for option: GovernanceSelectedOption) {
        metadataProvider = subscribeGovernanceMetadata(for: option)

        if metadataProvider == nil {
            presenter?.didReceiveReferendumsMetadata([])
        }
    }

    func provideBlockTime() {
        guard
            blockTimeCancellable == nil,
            let blockTimeService = governanceState.blockTimeService,
            let blockTimeFactory = governanceState.createBlockTimeOperationFactory(),
            let chain = governanceState.settings.value?.chain else {
            return
        }

        guard let runtimeProvider = chainRegistry.getRuntimeProvider(for: chain.chainId) else {
            presenter?.didReceiveError(.blockTimeFetchFailed(ChainRegistryError.runtimeMetadaUnavailable))
            return
        }

        let blockTimeWrapper = blockTimeFactory.createBlockTimeOperation(
            from: runtimeProvider,
            blockTimeEstimationService: blockTimeService
        )

        blockTimeWrapper.targetOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                guard self?.blockTimeCancellable === blockTimeWrapper else {
                    return
                }

                self?.blockTimeCancellable = nil

                do {
                    let blockTime = try blockTimeWrapper.targetOperation.extractNoCancellableResultData()

                    self?.presenter?.didReceiveBlockTime(blockTime)
                } catch {
                    self?.presenter?.didReceiveError(.blockTimeFetchFailed(error))
                }
            }
        }

        blockTimeCancellable = blockTimeWrapper

        operationQueue.addOperations(blockTimeWrapper.allOperations, waitUntilFinished: false)
    }

    func provideReferendumsIfNeeded(referendumIds: Set<ReferendumIdLocal>) {
        guard referendumsCancellable == nil else {
            return
        }

        guard let chain = governanceState.settings.value?.chain else {
            presenter?.didReceiveError(.referendumsFetchFailed(PersistentValueSettingsError.missingValue))
            return
        }

        guard let connection = chainRegistry.getConnection(for: chain.chainId) else {
            presenter?.didReceiveError(.referendumsFetchFailed(ChainRegistryError.connectionUnavailable))
            return
        }

        guard let runtimeProvider = chainRegistry.getRuntimeProvider(for: chain.chainId) else {
            presenter?.didReceiveError(.referendumsFetchFailed(ChainRegistryError.runtimeMetadaUnavailable))
            return
        }

        guard let referendumsOperationFactory = governanceState.referendumsOperationFactory else {
            presenter?.didReceiveReferendums([])
            return
        }

        let wrapper = referendumsOperationFactory.fetchReferendumsWrapper(for: referendumIds, connection: connection, runtimeProvider: runtimeProvider)

        wrapper.targetOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                guard wrapper === self?.referendumsCancellable else {
                    return
                }

                self?.referendumsCancellable = nil

                do {
                    let referendums = try wrapper.targetOperation.extractNoCancellableResultData()
                    self?.presenter?.didReceiveReferendums(referendums)
                } catch {
                    self?.presenter?.didReceiveError(.referendumsFetchFailed(error))
                }
            }
        }

        referendumsCancellable = wrapper

        operationQueue.addOperations(wrapper.allOperations, waitUntilFinished: false)
    }

    func provideOffchainVotingIfNeeded() {
        if offchainVotingCancellable == nil, let option = governanceState.settings.value {
            provideOffchainVoting(for: option)
        }
    }

    func provideOffchainVoting(for _: GovernanceSelectedOption) {
        clear(cancellable: &offchainVotingCancellable)

        let votingWrapper = governanceOffchainVotingFactory.createDirectVotesFetchOperation(for: address, from: nil)

        votingWrapper.targetOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                guard self?.offchainVotingCancellable === votingWrapper else {
                    return
                }

                self?.offchainVotingCancellable = nil

                do {
                    let voting = try votingWrapper.targetOperation.extractNoCancellableResultData()
                    self.provideReferendumsIfNeeded(referendumIds: Set(voting.keys))
                    self?.presenter?.didReceiveOffchainVoting(voting)
                } catch {
                    self?.presenter?.didReceiveError(.offchainVotingFetchFailed(error))
                }
            }
        }

        offchainVotingCancellable = votingWrapper

        operationQueue.addOperations(votingWrapper.allOperations, waitUntilFinished: false)
    }
}

extension DelegateVotedReferendaInteractor: DelegateVotedReferendaInteractorInputProtocol {
    func setup() {
        continueSetup()
    }

    func refresh() {
        if governanceState.settings.value != nil {
            provideBlockTime()
            metadataProvider?.refresh()
            provideOffchainVotingIfNeeded()
        }
    }

    func retryBlockTime() {
        provideBlockTime()
    }

    func retryOffchainVotingFetch() {
        provideOffchainVotingIfNeeded()
    }
}

extension DelegateVotedReferendaInteractor: GovMetadataLocalStorageSubscriber, GovMetadataLocalStorageHandler {
    var govMetadataLocalSubscriptionFactory: GovMetadataLocalSubscriptionFactoryProtocol {
        governanceState.govMetadataLocalSubscriptionFactory
    }

    func handleGovernanceMetadataPreview(
        result: Result<[DataProviderChange<ReferendumMetadataLocal>], Error>,
        option: GovernanceSelectedOption
    ) {
        guard let currentOption = governanceState.settings.value, currentOption == option else {
            return
        }

        switch result {
        case let .success(changes):
            presenter?.didReceiveReferendumsMetadata(changes)
        case let .failure(error): break
            presenter?.didReceiveError(.metadataSubscriptionFailed(error))
        }
    }
}

extension DelegateVotedReferendaInteractor: GeneralLocalStorageSubscriber, GeneralLocalStorageHandler {
    func handleBlockNumber(result: Result<BlockNumber?, Error>, chainId: ChainModel.Id) {
        guard let chain = governanceState.settings.value?.chain, chain.chainId == chainId else {
            return
        }

        switch result {
        case let .success(blockNumber):
            if let blockNumber = blockNumber {
                presenter?.didReceiveBlockNumber(blockNumber)
            }
        case let .failure(error): break
            presenter?.didReceiveError(.blockNumberSubscriptionFailed(error))
        }
    }
}
