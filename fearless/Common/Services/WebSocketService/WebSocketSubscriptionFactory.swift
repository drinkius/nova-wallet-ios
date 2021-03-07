import Foundation
import FearlessUtils
import IrohaCrypto
import RobinHood

final class WebSocketSubscriptionFactory: WebSocketSubscriptionFactoryProtocol {
    let storageFacade: StorageFacadeProtocol

    init(storageFacade: StorageFacadeProtocol) {
        self.storageFacade = storageFacade
    }

    func createSubscriptions(address: String,
                             type: SNAddressType,
                             engine: JSONRPCEngine) throws -> [WebSocketSubscribing] {
        let addressFactory = SS58AddressFactory()
        let accountId = try addressFactory.accountId(fromAddress: address, type: type)

        let keyFactory = StorageKeyFactory()
        let localStorageIdFactory = try ChainStorageIdFactory(chain: type.chain)

        let stakingSubscription = try createStakingSubscription(engine: engine,
                                                                accountId: accountId,
                                                                localStorageIdFactory: localStorageIdFactory)

        let transferSubscription = createTransferSubscription(address: address,
                                                              engine: engine,
                                                              networkType: type,
                                                              addressFactory: addressFactory,
                                                              localStorageIdFactory: localStorageIdFactory)

        let accountSubscription = try createAccountInfoSubscription(transferSubscription: transferSubscription,
                                                                    accountId: accountId,
                                                                    storageKeyFactory: keyFactory,
                                                                    localStorageIdFactory:
                                                                        localStorageIdFactory)

        let bondedSubscription = try createBondedSubscription(accountId: accountId,
                                                              stakingSubscription: stakingSubscription,
                                                              storageKeyFactory: keyFactory)

        let accountSubscriptions: [StorageChildSubscribing] = [
            accountSubscription,
            bondedSubscription
        ]

        let globalSubscriptions: [StorageChildSubscribing] = try createGlobalSubscriptions(
            keyFactory: keyFactory,
            localStorageIdFactory: localStorageIdFactory)

        let globalSubscriptionContainer = StorageSubscriptionContainer(engine: engine,
                                                                       children: globalSubscriptions,
                                                                       logger: Logger.shared)

        let accountSubscriptionContainer = StorageSubscriptionContainer(engine: engine,
                                                                        children: accountSubscriptions,
                                                                        logger: Logger.shared)

        let runtimeSubscription = createRuntimeVersionSubscription(engine: engine,
                                                                   networkType: type)

        return [globalSubscriptionContainer,
                accountSubscriptionContainer,
                stakingSubscription,
                runtimeSubscription]
    }

    private func createGlobalSubscriptions(keyFactory: StorageKeyFactoryProtocol,
                                           localStorageIdFactory: ChainStorageIdFactoryProtocol)
    throws -> [StorageChildSubscribing] {
        let upgradeV28Subscription = try createV28Subscription(
            storageKeyFactory: keyFactory,
            localStorageIdFactory: localStorageIdFactory)

        let activeEraSubscription = try createActiveEraSubscription(
            storageKeyFactory: keyFactory,
            localStorageIdFactory: localStorageIdFactory)

        let currentEraSubscription = try createCurrentEraSubscription(
            storageKeyFactory: keyFactory,
            localStorageIdFactory: localStorageIdFactory)

        let totalIssuanceSubscription = try createTotalIssuanceSubscription(
            storageKeyFactory: keyFactory,
            localStorageIdFactory: localStorageIdFactory)

        let subscriptions: [StorageChildSubscribing] = [
            upgradeV28Subscription,
            activeEraSubscription,
            currentEraSubscription,
            totalIssuanceSubscription
        ]

        return subscriptions
    }

    private func createAccountInfoSubscription(transferSubscription: TransferSubscription,
                                               accountId: Data,
                                               storageKeyFactory: StorageKeyFactoryProtocol,
                                               localStorageIdFactory: ChainStorageIdFactoryProtocol)
    throws -> AccountInfoSubscription {
        let accountStorageKey = try storageKeyFactory.accountInfoKeyForId(accountId)

        let localStorageKey = localStorageIdFactory.createIdentifier(for: accountStorageKey)

        let storage: CoreDataRepository<ChainStorageItem, CDChainStorageItem> =
            storageFacade.createRepository()

        return AccountInfoSubscription(transferSubscription: transferSubscription,
                                       remoteStorageKey: accountStorageKey,
                                       localStorageKey: localStorageKey,
                                       storage: AnyDataProviderRepository(storage),
                                       operationManager: OperationManagerFacade.sharedManager,
                                       logger: Logger.shared,
                                       eventCenter: EventCenter.shared)
    }

    private func createActiveEraSubscription(storageKeyFactory: StorageKeyFactoryProtocol,
                                             localStorageIdFactory: ChainStorageIdFactoryProtocol)
    throws -> ActiveEraSubscription {
        let remoteStorageKey = try storageKeyFactory.activeEra()
        let localStorageKey = localStorageIdFactory.createIdentifier(for: remoteStorageKey)

        let storage: CoreDataRepository<ChainStorageItem, CDChainStorageItem> =
            storageFacade.createRepository()

        return ActiveEraSubscription(remoteStorageKey: remoteStorageKey,
                                     localStorageKey: localStorageKey,
                                     storage: AnyDataProviderRepository(storage),
                                     operationManager: OperationManagerFacade.sharedManager,
                                     logger: Logger.shared,
                                     eventCenter: EventCenter.shared)
    }

    private func createCurrentEraSubscription(storageKeyFactory: StorageKeyFactoryProtocol,
                                              localStorageIdFactory: ChainStorageIdFactoryProtocol)
    throws -> CurrentEraSubscription {
        let remoteStorageKey = try storageKeyFactory.currentEra()
        let localStorageKey = localStorageIdFactory.createIdentifier(for: remoteStorageKey)

        let storage: CoreDataRepository<ChainStorageItem, CDChainStorageItem> =
            storageFacade.createRepository()

        return CurrentEraSubscription(remoteStorageKey: remoteStorageKey,
                                      localStorageKey: localStorageKey,
                                      storage: AnyDataProviderRepository(storage),
                                      operationManager: OperationManagerFacade.sharedManager,
                                      logger: Logger.shared,
                                      eventCenter: EventCenter.shared)
    }

    private func createTotalIssuanceSubscription(storageKeyFactory: StorageKeyFactoryProtocol,
                                                 localStorageIdFactory: ChainStorageIdFactoryProtocol)
    throws -> TotalIssuanceSubscription {
        let remoteStorageKey = try storageKeyFactory.totalIssuance()
        let localStorageKey = localStorageIdFactory.createIdentifier(for: remoteStorageKey)

        let storage: CoreDataRepository<ChainStorageItem, CDChainStorageItem> =
            storageFacade.createRepository()

        return TotalIssuanceSubscription(remoteStorageKey: remoteStorageKey,
                                         localStorageKey: localStorageKey,
                                         storage: AnyDataProviderRepository(storage),
                                         operationManager: OperationManagerFacade.sharedManager,
                                         logger: Logger.shared,
                                         eventCenter: EventCenter.shared)
    }

    private func createStakingSubscription(engine: JSONRPCEngine,
                                           accountId: Data,
                                           localStorageIdFactory: ChainStorageIdFactoryProtocol)
    throws -> StakingInfoSubscription {

        let storage: CoreDataRepository<ChainStorageItem, CDChainStorageItem> =
            storageFacade.createRepository()

        return StakingInfoSubscription(engine: engine,
                                       stashId: accountId,
                                       storage: AnyDataProviderRepository(storage),
                                       localStorageIdFactory: localStorageIdFactory,
                                       operationManager: OperationManagerFacade.sharedManager,
                                       eventCenter: EventCenter.shared,
                                       logger: Logger.shared)
    }

    private func createBondedSubscription(accountId: Data,
                                          stakingSubscription: StakingInfoSubscription,
                                          storageKeyFactory: StorageKeyFactoryProtocol)
    throws -> BondedSubscription {
        let storageKey = try storageKeyFactory.bondedKeyForId(accountId)

        return BondedSubscription(remoteStorageKey: storageKey,
                                  stakingSubscription: stakingSubscription,
                                  logger: Logger.shared)
    }

    private func createV28Subscription(storageKeyFactory: StorageKeyFactoryProtocol,
                                       localStorageIdFactory: ChainStorageIdFactoryProtocol)
    throws -> UpgradeV28Subscription {
        let remoteStorageKey = try storageKeyFactory.updatedDualRefCount()
        let localStorageKey = localStorageIdFactory.createIdentifier(for: remoteStorageKey)

        let storage: CoreDataRepository<ChainStorageItem, CDChainStorageItem> =
            storageFacade.createRepository()

        return UpgradeV28Subscription(remoteStorageKey: remoteStorageKey,
                                      localStorageKey: localStorageKey,
                                      storage: AnyDataProviderRepository(storage),
                                      operationManager: OperationManagerFacade.sharedManager,
                                      logger: Logger.shared,
                                      eventCenter: EventCenter.shared)
    }

    private func createTransferSubscription(address: String,
                                            engine: JSONRPCEngine,
                                            networkType: SNAddressType,
                                            addressFactory: SS58AddressFactoryProtocol,
                                            localStorageIdFactory: ChainStorageIdFactoryProtocol)
    -> TransferSubscription {
        let filter = NSPredicate.filterTransactionsBy(address: address)
        let txStorage: CoreDataRepository<TransactionHistoryItem, CDTransactionHistoryItem> =
            storageFacade.createRepository(filter: filter)

        let chainStorage: CoreDataRepository<ChainStorageItem, CDChainStorageItem> =
            storageFacade.createRepository()

        let contactOperationFactory = WalletContactOperationFactory(storageFacade: storageFacade,
                                                                    targetAddress: address)

        return TransferSubscription(engine: engine,
                                    address: address,
                                    chain: networkType.chain,
                                    addressFactory: addressFactory,
                                    txStorage: AnyDataProviderRepository(txStorage),
                                    chainStorage: AnyDataProviderRepository(chainStorage),
                                    localIdFactory: localStorageIdFactory,
                                    contactOperationFactory: contactOperationFactory,
                                    operationManager: OperationManagerFacade.sharedManager,
                                    eventCenter: EventCenter.shared,
                                    logger: Logger.shared)
    }

    private func createRuntimeVersionSubscription(engine: JSONRPCEngine,
                                                  networkType: SNAddressType)
    -> RuntimeVersionSubscription {
        let chain = networkType.chain

        let filter = NSPredicate.filterRuntimeMetadataItemsBy(identifier: chain.genesisHash)
        let storage: CoreDataRepository<RuntimeMetadataItem, CDRuntimeMetadataItem> =
            storageFacade.createRepository(filter: filter)

        return RuntimeVersionSubscription(chain: chain,
                                          storage: AnyDataProviderRepository(storage),
                                          engine: engine,
                                          operationManager: OperationManagerFacade.sharedManager,
                                          logger: Logger.shared)
    }
}
