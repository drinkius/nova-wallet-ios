import Foundation
import SubstrateSdk

extension Xcm {
    enum WeightLimit: Encodable {
        case unlimited
        case limited(weight: UInt64)

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()

            switch self {
            case .unlimited:
                try container.encode("Unlimited")
            case let .limited(weight):
                try container.encode("Limited")
                try container.encode(StringScaleMapper(value: weight))
            }
        }
    }
}
