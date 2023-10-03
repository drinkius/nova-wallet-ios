import Foundation
import SubstrateSdk
import BigInt

struct AssetHubToken {
    let assetId: ChainAssetId
    let extras: StatemineAssetExtras
}

enum AssetHubTokensConverter {
    static func convertToMultilocation(
        chainAssetId: ChainAssetId,
        chain: ChainModel,
        codingFactory: RuntimeCoderFactoryProtocol
    ) -> AssetConversionPallet.AssetId? {
        guard
            chain.chainId == chainAssetId.chainId,
            let localAsset = chain.asset(for: chainAssetId.assetId) else {
            return nil
        }

        return convertToMultilocation(asset: localAsset, codingFactory: codingFactory)
    }

    static func convertToMultilocation(
        asset: AssetModel,
        codingFactory: RuntimeCoderFactoryProtocol
    ) -> AssetConversionPallet.AssetId? {
        guard let storageInfo = try? AssetStorageInfo.extract(from: asset, codingFactory: codingFactory) else {
            return nil
        }

        switch storageInfo {
        case .native:
            return .init(parents: 0, interior: .init(items: []))
        case let .statemine(extras):
            let palletName = extras.palletName ?? PalletAssets.name

            guard
                let palletIndex = codingFactory.metadata.getModuleIndex(palletName),
                let generalIndex = BigUInt(extras.assetId) else {
                return nil
            }

            let palletJunction = XcmV3.Junction.palletInstance(palletIndex)
            let generalIndexJunction = XcmV3.Junction.generalIndex(generalIndex)

            return .init(parents: 0, interior: .init(items: [palletJunction, generalIndexJunction]))
        default:
            return nil
        }
    }
}
