import Foundation
import BigInt
import SubstrateSdk

enum AstarDappStaking {
    static let module = "DappStaking"

    static var stakingLedger: StorageCodingPath {
        StorageCodingPath(moduleName: module, itemName: "Ledger")
    }
}
