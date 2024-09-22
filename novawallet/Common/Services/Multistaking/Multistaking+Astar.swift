import Foundation
import SubstrateSdk

extension Multistaking {
    struct AstarAccountsChange: BatchStorageSubscriptionResult {
        enum Key: String {
            case stash
        }

        let ledger: UncertainStorage<AccountLedger?>

        init(
            values: [BatchStorageSubscriptionResultValue],
            blockHashJson _: JSON,
            context: [CodingUserInfoKey: Any]?
        ) throws {
            ledger = try UncertainStorage<AccountLedger?>(
                values: values,
                mappingKey: Key.stash.rawValue,
                context: context
            )
        }
    }

    struct AstarState {
        let ledger: AccountLedger?

        func applying(change: AstarStateChange) -> AstarState {
            let newLedger = change.ledger.valueWhenDefined(else: ledger)

            return .init(
                ledger: newLedger
            )
        }
    }

    struct AstarStateChange: BatchStorageSubscriptionResult {
        enum Key: String {
            case ledger
        }

        let ledger: UncertainStorage<AccountLedger?>

        init(
            values: [BatchStorageSubscriptionResultValue],
            blockHashJson _: JSON,
            context: [CodingUserInfoKey: Any]?
        ) throws {
            ledger = try UncertainStorage(
                values: values,
                mappingKey: Key.ledger.rawValue,
                context: context
            )
        }
    }
}
