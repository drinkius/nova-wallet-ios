import Foundation
import Operation_iOS

protocol AnyCancellableCleaning {
    func clear(cancellable: inout CancellableCall?)
}

extension AnyCancellableCleaning {
    func clear(cancellable: inout CancellableCall?) {
        let copy = cancellable
        cancellable = nil
        copy?.cancel()
    }
}
