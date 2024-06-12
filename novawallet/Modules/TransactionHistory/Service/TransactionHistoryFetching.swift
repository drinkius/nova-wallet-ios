import Foundation
import Operation_iOS

enum TransactionHistoryFetcherError: Error {
    case remoteFetchFailed(Error)
}

protocol TransactionHistoryFetcherDelegate: AnyObject {
    func didReceiveHistoryChanges(
        _ fetcher: TransactionHistoryFetching,
        changes: [DataProviderChange<TransactionHistoryItem>]
    )

    func didReceiveHistoryError(_ fetcher: TransactionHistoryFetching, error: TransactionHistoryFetcherError)

    func didUpdateFetchingState()
}

protocol TransactionHistoryFetching: AnyObject {
    var delegate: TransactionHistoryFetcherDelegate? { get set }

    var isComplete: Bool { get }

    var isFetching: Bool { get }

    func start()

    func fetchNext()
}
