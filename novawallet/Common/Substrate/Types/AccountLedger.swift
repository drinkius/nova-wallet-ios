import Foundation
import SubstrateSdk
import BigInt

struct AccountLedger: Decodable, Equatable {
    @StringCodable var locked: BigUInt
}
