typealias KiltTransferAssetRecipientResponse = [String: [Web3NameTransferAssetRecipientAccount]]

struct Web3NameTransferAssetRecipientAccount: Codable {
    let account: String
    let description: String?

    func isValid(using chainFormat: ChainFormat?) -> Bool {
        let accountId: AccountId?
        if let chainFormat = chainFormat {
            accountId = try? account.toAccountId(using: chainFormat)
        } else {
            accountId = try? account.toAccountId()
        }
        return accountId != nil
    }
}
