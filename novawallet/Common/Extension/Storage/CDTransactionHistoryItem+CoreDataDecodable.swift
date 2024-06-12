import Foundation
import Operation_iOS
import CoreData

extension CDTransactionItem: CoreDataCodable {
    public func populate(from decoder: Decoder, using context: NSManagedObjectContext) throws {
        let container = try decoder.container(keyedBy: TransactionHistoryItem.CodingKeys.self)

        let identifier = try container.decode(String.self, forKey: .identifier)
        let sourceValue = try container.decode(TransactionHistoryItemSource.self, forKey: .source)
        source = sourceValue.rawValue
        chainId = try container.decode(String.self, forKey: .chainId)

        let assetId = try container.decode(UInt32.self, forKey: .assetId)
        self.assetId = Int32(bitPattern: assetId)

        let hash = try container.decode(String.self, forKey: .txHash)
        txHash = hash
        self.identifier = identifier

        sender = try container.decode(String.self, forKey: .sender)
        receiver = try container.decodeIfPresent(String.self, forKey: .receiver)
        amountInPlank = try container.decodeIfPresent(String.self, forKey: .amountInPlank)
        status = try container.decode(Int16.self, forKey: .status)

        timestamp = try container.decode(Int64.self, forKey: .timestamp)

        if let fee = try container.decodeIfPresent(String.self, forKey: .fee) {
            self.fee = fee
        }
        if let feeAssetId = try container.decodeIfPresent(UInt32.self, forKey: .feeAssetId) {
            self.feeAssetId = NSNumber(value: feeAssetId)
        } else {
            feeAssetId = nil
        }
        let callPath = try container.decode(CallCodingPath.self, forKey: .callPath)
        callName = callPath.callName
        moduleName = callPath.moduleName

        call = try container.decodeIfPresent(Data.self, forKey: .call)

        if let number = try container.decodeIfPresent(UInt64.self, forKey: .blockNumber) {
            blockNumber = NSNumber(value: number)
        } else {
            blockNumber = nil
        }

        if let index = try container.decodeIfPresent(Int16.self, forKey: .txIndex) {
            txIndex = NSNumber(value: index)
        } else {
            txIndex = nil
        }
        if let swapContainer = try? container.nestedContainer(keyedBy: SwapHistoryData.CodingKeys.self, forKey: .swap) {
            if swap == nil {
                let newSwap = CDTransactionSwapItem(context: context)
                newSwap.transaction = self
                swap = newSwap
            }
            swap?.amountIn = try swapContainer.decode(String.self, forKey: .amountIn)
            swap?.amountOut = try swapContainer.decode(String.self, forKey: .amountOut)

            let assetIdIn = try swapContainer.decodeIfPresent(UInt32.self, forKey: .assetIdIn)
            swap?.assetIdIn = assetIdIn.map { NSNumber(value: Int32(bitPattern: $0)) }

            let assetIdOut = try swapContainer.decodeIfPresent(UInt32.self, forKey: .assetIdOut)
            swap?.assetIdOut = assetIdOut.map { NSNumber(value: Int32(bitPattern: $0)) }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: TransactionHistoryItem.CodingKeys.self)

        let feeAssetId = feeAssetId.map { UInt32(bitPattern: $0.int32Value) }

        try container.encodeIfPresent(identifier, forKey: .identifier)
        try container.encodeIfPresent(TransactionHistoryItemSource(rawValue: source), forKey: .source)
        try container.encodeIfPresent(chainId, forKey: .chainId)
        try container.encode(UInt32(bitPattern: assetId), forKey: .assetId)
        try container.encodeIfPresent(txHash, forKey: .txHash)
        try container.encodeIfPresent(sender, forKey: .sender)
        try container.encodeIfPresent(receiver, forKey: .receiver)
        try container.encodeIfPresent(amountInPlank, forKey: .amountInPlank)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(fee, forKey: .fee)
        try container.encodeIfPresent(feeAssetId, forKey: .feeAssetId)
        try container.encodeIfPresent(blockNumber?.uint64Value, forKey: .blockNumber)
        try container.encodeIfPresent(txIndex?.int16Value, forKey: .txIndex)

        if let moduleName = moduleName, let callName = callName {
            let callPath = CallCodingPath(moduleName: moduleName, callName: callName)
            try container.encode(callPath, forKey: .callPath)
        }

        try container.encodeIfPresent(call, forKey: .call)

        if let swap = swap {
            var nestedSwap = container.nestedContainer(keyedBy: SwapHistoryData.CodingKeys.self, forKey: .swap)
            try nestedSwap.encode(swap.amountIn, forKey: .amountIn)
            try nestedSwap.encode(swap.amountOut, forKey: .amountOut)
            try nestedSwap.encodeIfPresent(
                swap.assetIdIn.map { UInt32(bitPattern: $0.int32Value) },
                forKey: .assetIdIn
            )

            try nestedSwap.encodeIfPresent(
                swap.assetIdOut.map { UInt32(bitPattern: $0.int32Value) },
                forKey: .assetIdOut
            )
        }
    }
}
