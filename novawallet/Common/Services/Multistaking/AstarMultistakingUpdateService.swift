import Foundation
import SubstrateSdk
import Operation_iOS

final class AstarMultistakingUpdateService: ObservableSyncService {
    let accountId: AccountId
    let walletId: MetaAccountModel.Id
    let chainAsset: ChainAsset
    let stakingType: StakingType
    let connection: JSONRPCEngine
    let runtimeService: RuntimeCodingServiceProtocol
    let dashboardRepository: AnyDataProviderRepository<Multistaking.DashboardItemAstarPart>
    let accountRepository: AnyDataProviderRepository<Multistaking.ResolvedAccount>
    let cacheRepository: AnyDataProviderRepository<ChainStorageItem>
    let stashItemRepository: AnyDataProviderRepository<StashItem>
    let workingQueue: DispatchQueue
    let operationQueue: OperationQueue

    private var stateSubscription: CallbackBatchStorageSubscription<Multistaking.AstarStateChange>?

    private var controllerSubscription: CallbackBatchStorageSubscription<Multistaking.AstarAccountsChange>?

    private var state: Multistaking.AstarState?

    init(
        walletId: MetaAccountModel.Id,
        accountId: AccountId,
        chainAsset: ChainAsset,
        stakingType: StakingType,
        dashboardRepository: AnyDataProviderRepository<Multistaking.DashboardItemAstarPart>,
        accountRepository: AnyDataProviderRepository<Multistaking.ResolvedAccount>,
        cacheRepository: AnyDataProviderRepository<ChainStorageItem>,
        stashItemRepository: AnyDataProviderRepository<StashItem>,
        connection: JSONRPCEngine,
        runtimeService: RuntimeCodingServiceProtocol,
        operationQueue: OperationQueue,
        workingQueue: DispatchQueue,
        logger: LoggerProtocol
    ) {
        self.walletId = walletId
        self.accountId = accountId
        self.chainAsset = chainAsset
        self.stakingType = stakingType
        self.dashboardRepository = dashboardRepository
        self.accountRepository = accountRepository
        self.cacheRepository = cacheRepository
        self.stashItemRepository = stashItemRepository
        self.connection = connection
        self.runtimeService = runtimeService
        self.workingQueue = workingQueue
        self.operationQueue = operationQueue

        super.init(logger: logger)
    }

    override func performSyncUp() {
        clearSubscriptions()

        subscribeControllerResolution(for: accountId)
    }

    override func stopSyncUp() {
        clearSubscriptions()
    }

    private func clearSubscriptions() {
        clearControllerSubscription()
        clearStateSubscription()
    }

    private func clearControllerSubscription() {
        controllerSubscription?.unsubscribe()
        controllerSubscription = nil
    }

    private func clearStateSubscription() {
        stateSubscription?.unsubscribe()
        stateSubscription = nil
    }

    private func subscribeControllerResolution(for accountId: AccountId) {
        let ledgerRequest = BatchStorageSubscriptionRequest(
            innerRequest: MapSubscriptionRequest(
                storagePath: AstarDappStaking.stakingLedger,
                localKey: ""
            ) {
                BytesCodable(wrappedValue: accountId)
            },
            mappingKey: Multistaking.AstarAccountsChange.Key.stash.rawValue
        )

        controllerSubscription = CallbackBatchStorageSubscription(
            requests: [ledgerRequest], // [controllerRequest, ledgerRequest],
            connection: connection,
            runtimeService: runtimeService,
            repository: nil,
            operationQueue: operationQueue,
            callbackQueue: workingQueue
        ) { [weak self] result in
            self?.mutex.lock()

            self?.handleControllerSubscription(result: result, accountId: accountId)

            self?.mutex.unlock()
        }

        controllerSubscription?.subscribe()
    }

    private func handleControllerSubscription(
        result: Result<Multistaking.AstarAccountsChange, Error>,
        accountId: AccountId
    ) {
        switch result {
        case let .success:
            markSyncingImmediate()

            let controller: AccountId = accountId
            subscribeState(for: controller)
        case let .failure(error):
            completeImmediate(error)
        }
    }

    // swiftlint:disable:next function_body_length
    private func subscribeState(for controller: AccountId) {
        do {
            clearStateSubscription()

            let localKeyFactory = LocalStorageKeyFactory()

            let ledgerLocalKey = try localKeyFactory.createFromStoragePath(
                AstarDappStaking.stakingLedger,
                accountId: controller,
                chainId: chainAsset.chain.chainId
            )

            let ledgerRequest = BatchStorageSubscriptionRequest(
                innerRequest: MapSubscriptionRequest(
                    storagePath: AstarDappStaking.stakingLedger,
                    localKey: ledgerLocalKey
                ) {
                    BytesCodable(wrappedValue: controller)
                },
                mappingKey: Multistaking.AstarStateChange.Key.ledger.rawValue
            )

            stateSubscription = CallbackBatchStorageSubscription(
                requests: [ledgerRequest],
                connection: connection,
                runtimeService: runtimeService,
                repository: cacheRepository,
                operationQueue: operationQueue,
                callbackQueue: workingQueue
            ) { [weak self] result in
                self?.mutex.lock()

                self?.handleStateSubscription(result: result)

                self?.mutex.unlock()
            }

            stateSubscription?.subscribe()
        } catch {
            logger.error("Local key failed: \(error)")
            completeImmediate(error)
        }
    }

    private func handleStateSubscription(result: Result<Multistaking.AstarStateChange, Error>) {
        switch result {
        case let .success(change):
            if let newState = updateState(from: change) {
                saveState(newState)
            }
        case let .failure(error):
            completeImmediate(error)
        }
    }

    private func updateState(from change: Multistaking.AstarStateChange) -> Multistaking.AstarState? {
        if let currentState = state {
            let newState = currentState.applying(change: change)
            state = newState
            return newState
        } else if
            case let .defined(ledger) = change.ledger {
            let state = Multistaking.AstarState(
                ledger: ledger
            )

            self.state = state

            return state
        } else {
            return nil
        }
    }

    private func saveResolvedAccounts(_ stashAccountId: AccountId) {
        let stakingOption = Multistaking.Option(
            chainAssetId: chainAsset.chainAssetId,
            type: stakingType
        )

        let resolvedAccount = Multistaking.ResolvedAccount(
            stakingOption: stakingOption,
            walletAccountId: accountId,
            resolvedAccountId: stashAccountId,
            rewardsAccountId: stashAccountId
        )

        let saveOperation = accountRepository.saveOperation({
            [resolvedAccount]
        }, {
            []
        })

        saveOperation.completionBlock = { [weak self] in
            self?.workingQueue.async {
                do {
                    _ = try saveOperation.extractNoCancellableResultData()
                } catch {
                    self?.logger.error("Can't save stash account id")
                }
            }
        }

        operationQueue.addOperation(saveOperation)
    }

    private func saveState(_ state: Multistaking.AstarState) {
        let stakingOption = Multistaking.OptionWithWallet(
            walletId: walletId,
            option: .init(chainAssetId: chainAsset.chainAssetId, type: stakingType)
        )

        let dashboardItem = Multistaking.DashboardItemAstarPart(
            stakingOption: stakingOption,
            state: state
        )

        let saveOperation = dashboardRepository.saveOperation({
            [dashboardItem]
        }, {
            []
        })

        saveOperation.completionBlock = { [weak self] in
            self?.workingQueue.async {
                do {
                    _ = try saveOperation.extractNoCancellableResultData()
                    self?.complete(nil)
                } catch {
                    self?.complete(error)
                }
            }
        }

        operationQueue.addOperation(saveOperation)
    }
}
