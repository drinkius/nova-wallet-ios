import Foundation
import BigInt
import Operation_iOS
import CoreData

extension Multistaking.DashboardItemAstarPart: Identifiable {
    var identifier: String { stakingOption.stringValue }
}

final class StakingDashboardAstarMapper {
    var entityIdentifierFieldName: String { #keyPath(CDStakingDashboardItem.identifier) }

    typealias DataProviderModel = Multistaking.DashboardItemAstarPart
    typealias CoreDataEntity = CDStakingDashboardItem
}

extension StakingDashboardAstarMapper: CoreDataMapperProtocol {
    func populate(
        entity: CoreDataEntity,
        from model: DataProviderModel,
        using _: NSManagedObjectContext
    ) throws {
        entity.identifier = model.identifier
        entity.walletId = model.stakingOption.walletId

        let chainAssetId = model.stakingOption.option.chainAssetId
        entity.chainId = chainAssetId.chainId
        entity.assetId = Int32(bitPattern: chainAssetId.assetId)

        entity.stakingType = model.stakingOption.option.type.rawValue

        entity.stake = model.state.ledger.map { String($0.locked) }
        entity.onchainState = Multistaking.DashboardItemOnchainState.from(astarState: model.state)?.rawValue
    }

    func transform(entity _: CoreDataEntity) throws -> DataProviderModel {
        // we only can write partial state but not read
        fatalError("Unsupported method")
    }
}
