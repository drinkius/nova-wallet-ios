import Foundation
import RobinHood
import CommonWallet
import IrohaCrypto

extension WalletNetworkFacade {
    func createHistoryMergeOperation(
        dependingOn remoteOperation: BaseOperation<WalletRemoteHistoryData>?,
        localOperation: BaseOperation<[TransactionHistoryItem]>?,
        codingFactoryOperation: BaseOperation<RuntimeCoderFactoryProtocol>,
        chainAssetInfo: ChainAssetDisplayInfo,
        assetId: String,
        address: String
    ) -> BaseOperation<TransactionHistoryMergeResult> {
        ClosureOperation {
            let remoteTransactions = try remoteOperation?.extractNoCancellableResultData().historyItems ?? []

            if let localTransactions = try localOperation?.extractNoCancellableResultData(),
               !localTransactions.isEmpty {
                let manager = TransactionHistoryMergeManager(
                    address: address,
                    chainAssetInfo: chainAssetInfo,
                    assetId: assetId
                )

                let coderFactory = try codingFactoryOperation.extractNoCancellableResultData()
                let runtimeJsonContext = coderFactory.createRuntimeJsonContext()

                return manager.merge(
                    subscanItems: remoteTransactions,
                    localItems: localTransactions,
                    runtimeJsonContext: runtimeJsonContext
                )
            } else {
                let transactions: [AssetTransactionData] = remoteTransactions.map { item in
                    item.createTransactionForAddress(
                        address,
                        assetId: assetId,
                        chainAssetInfo: chainAssetInfo
                    )
                }

                return TransactionHistoryMergeResult(
                    historyItems: transactions,
                    identifiersToRemove: []
                )
            }
        }
    }

    func createHistoryMapOperation(
        dependingOn mergeOperation: BaseOperation<TransactionHistoryMergeResult>,
        remoteOperation: BaseOperation<WalletRemoteHistoryData>
    ) -> BaseOperation<AssetTransactionPageData?> {
        ClosureOperation {
            let mergeResult = try mergeOperation.extractNoCancellableResultData()
            let newHistoryContext = try remoteOperation.extractNoCancellableResultData().context

            return AssetTransactionPageData(
                transactions: mergeResult.historyItems,
                context: newHistoryContext
            )
        }
    }
}
