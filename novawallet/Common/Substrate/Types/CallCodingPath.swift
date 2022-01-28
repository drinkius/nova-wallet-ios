import Foundation

struct CallCodingPath: Equatable, Codable {
    let moduleName: String
    let callName: String
}

extension CallCodingPath {
    var isTransfer: Bool {
        [.transfer, .transferKeepAlive].contains(self)
    }

    static var transfer: CallCodingPath {
        CallCodingPath(moduleName: "Balances", callName: "transfer")
    }

    static var transferKeepAlive: CallCodingPath {
        CallCodingPath(moduleName: "Balances", callName: "transfer_keep_alive")
    }

    static var tokensTransfer: CallCodingPath {
        CallCodingPath(moduleName: "Tokens", callName: "transfer")
    }

    static var currenciesTransfer: CallCodingPath {
        CallCodingPath(moduleName: "Currencies", callName: "transfer")
    }
}
