import Foundation
import Operation_iOS

struct ManagedMetaAccountModel: Equatable, Hashable {
    static let noOrder: UInt32 = 0

    let info: MetaAccountModel
    let isSelected: Bool
    let order: UInt32

    init(info: MetaAccountModel, isSelected: Bool = false, order: UInt32 = Self.noOrder) {
        self.info = info
        self.isSelected = isSelected
        self.order = order
    }
}

extension ManagedMetaAccountModel: Identifiable {
    var identifier: String { info.metaId }
}

extension ManagedMetaAccountModel {
    func replacingOrder(_ newOrder: UInt32) -> ManagedMetaAccountModel {
        ManagedMetaAccountModel(info: info, isSelected: isSelected, order: newOrder)
    }

    func replacingInfo(_ newInfo: MetaAccountModel) -> ManagedMetaAccountModel {
        ManagedMetaAccountModel(info: newInfo, isSelected: isSelected, order: order)
    }

    func replacingSelection(_ isSelected: Bool) -> ManagedMetaAccountModel {
        ManagedMetaAccountModel(info: info, isSelected: isSelected, order: order)
    }
}

extension Array where Element == ManagedMetaAccountModel {
    func has(accountId: AccountId, in chainModel: ChainModel) -> Bool {
        contains {
            $0.info.has(accountId: accountId, chainId: chainModel.chainId)
        }
    }
}
