import Foundation
import SubstrateSdk
import BigInt

extension HydraDx {
    struct QuoteRemoteState {
        let assetInState: HydraDx.AssetState?
        let assetOutState: HydraDx.AssetState?
        let assetInBalance: BigUInt?
        let assetOutBalance: BigUInt?
        let assetInFee: BigUInt?
        let assetOutFee: BigUInt?
        let blockHash: Data?

        func merging(newStateChange: QuoteRemoteStateChange) -> QuoteRemoteState {
            .init(
                assetInState: newStateChange.assetInState.valueWhenDefined(else: assetInState),
                assetOutState: newStateChange.assetOutState.valueWhenDefined(else: assetOutState),
                assetInBalance: newStateChange.assetInBalance.valueWhenDefined(else: assetInBalance),
                assetOutBalance: newStateChange.assetInBalance.valueWhenDefined(else: assetOutBalance),
                assetInFee: newStateChange.assetInFee.valueWhenDefined(else: assetInFee),
                assetOutFee: newStateChange.assetInFee.valueWhenDefined(else: assetOutFee),
                blockHash: newStateChange.blockHash
            )
        }
    }

    struct QuoteRemoteStateChange: BatchStorageSubscriptionResult {
        enum Key: String {
            case assetInState
            case assetOutState
            case assetInNativeBalance
            case assetInOrmlBalance
            case assetOutNativeBalance
            case assetOutOrmlBalance
            case assetInFee
            case assetOutFee
        }

        let assetInState: UncertainStorage<HydraDx.AssetState?>
        let assetOutState: UncertainStorage<HydraDx.AssetState?>
        let assetInBalance: UncertainStorage<BigUInt?>
        let assetOutBalance: UncertainStorage<BigUInt?>
        let assetInFee: UncertainStorage<BigUInt?>
        let assetOutFee: UncertainStorage<BigUInt?>
        let blockHash: Data?

        init(
            assetInState: UncertainStorage<HydraDx.AssetState?>,
            assetOutState: UncertainStorage<HydraDx.AssetState?>,
            assetInBalance: UncertainStorage<BigUInt?>,
            assetOutBalance: UncertainStorage<BigUInt?>,
            assetInFee: UncertainStorage<BigUInt?>,
            assetOutFee: UncertainStorage<BigUInt?>,
            blockHash: Data?
        ) {
            self.assetInState = assetInState
            self.assetOutState = assetOutState
            self.assetInBalance = assetInBalance
            self.assetOutBalance = assetOutBalance
            self.assetInFee = assetInFee
            self.assetOutFee = assetOutFee
            self.blockHash = blockHash
        }

        init(
            values: [BatchStorageSubscriptionResultValue],
            blockHashJson: JSON,
            context: [CodingUserInfoKey: Any]?
        ) throws {
            assetInState = try UncertainStorage(
                values: values,
                mappingKey: Key.assetInState.rawValue,
                context: context
            )

            assetOutState = try UncertainStorage(
                values: values,
                mappingKey: Key.assetOutState.rawValue,
                context: context
            )

            assetInBalance = try Self.getBalanceStorage(
                for: values,
                nativeKey: Key.assetInNativeBalance,
                ormlKey: Key.assetInOrmlBalance,
                context: context
            )

            assetOutBalance = try Self.getBalanceStorage(
                for: values,
                nativeKey: Key.assetOutNativeBalance,
                ormlKey: Key.assetOutOrmlBalance,
                context: context
            )

            assetInFee = try UncertainStorage<StringScaleMapper<BigUInt>?>(
                values: values,
                mappingKey: Key.assetInFee.rawValue,
                context: context
            ).map { $0?.value }

            assetOutFee = try UncertainStorage<StringScaleMapper<BigUInt>?>(
                values: values,
                mappingKey: Key.assetOutFee.rawValue,
                context: context
            ).map { $0?.value }

            blockHash = try blockHashJson.map(to: Data?.self, with: context)
        }

        static func getBalanceStorage(
            for values: [BatchStorageSubscriptionResultValue],
            nativeKey: Key,
            ormlKey: Key,
            context: [CodingUserInfoKey: Any]?
        ) throws -> UncertainStorage<BigUInt?> {
            let nativeBalance = try UncertainStorage<AccountInfo?>(
                values: values,
                mappingKey: nativeKey.rawValue,
                context: context
            ).map { $0?.data.free }

            if let balance = nativeBalance.value {
                return .defined(balance)
            }

            let ormlBalance = try UncertainStorage<OrmlAccount?>(
                values: values,
                mappingKey: ormlKey.rawValue,
                context: context
            ).map { $0?.free }

            return ormlBalance
        }
    }
}
