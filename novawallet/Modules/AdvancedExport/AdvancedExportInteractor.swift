import SoraKeystore

final class AdvancedExportInteractor {
    weak var presenter: AdvancedExportInteractorOutputProtocol?

    private let keystore: KeystoreProtocol

    init(keystore: KeystoreProtocol) {
        self.keystore = keystore
    }
}

extension AdvancedExportInteractor: AdvancedExportInteractorInputProtocol {
    func requestExportOptions(
        metaAccount: MetaAccountModel,
        chain: ChainModel?
    ) {
        do {
            let substrateExportData = try substrateExportData(
                for: metaAccount,
                chain: chain
            )

            let ethereumExportData = try ethereumExportData(
                for: metaAccount,
                chain: chain
            )

            let exportData = AdvancedExportData(
                chains: [
                    .substrate(substrateExportData),
                    .ethereum(ethereumExportData)
                ]
            )

            presenter?.didReceive(exportData: exportData)
        } catch {
            presenter?.didReceive(error)
        }
    }

    func requestSeedForSubstrate(
        metaAccount: MetaAccountModel,
        chain: ChainModel?
    ) {
        guard let secret = fetchSecret(
            with: metaAccount,
            chain: chain,
            chainType: .substrate
        ) else {
            return
        }

        presenter?.didReceive(
            seed: secret,
            for: chain?.name ?? ChainType.substrate.rawValue
        )
    }

    func requestKeyForEthereum(
        metaAccount: MetaAccountModel,
        chain: ChainModel?
    ) {
        guard let secret = fetchSecret(
            with: metaAccount,
            chain: chain,
            chainType: .ethereum
        ) else {
            return
        }

        presenter?.didReceive(
            seed: secret,
            for: chain?.name ?? ChainType.ethereum.rawValue
        )
    }
}

// MARK: Private

private extension AdvancedExportInteractor {
    func fetchSecret(
        with metaAccount: MetaAccountModel,
        chain: ChainModel?,
        chainType: ChainType
    ) -> Data? {
        var accountId: AccountId?

        if let chain {
            accountId = metaAccount.fetchChainAccountId(for: chain.accountRequest())
        }

        let keystoreTag: String = switch chainType {
        case .ethereum:
            KeystoreTagV2.ethereumSecretKeyTagForMetaId(
                metaAccount.metaId,
                accountId: accountId
            )
        case .substrate:
            KeystoreTagV2.substrateSeedTagForMetaId(
                metaAccount.metaId,
                accountId: accountId
            )
        }

        return try? keystore.loadIfKeyExists(keystoreTag)
    }

    func ethereumExportData(
        for metaAccount: MetaAccountModel,
        chain: ChainModel?
    ) throws -> AdvancedExportChainData {
        var accountResponse: ChainAccountResponse?
        var accountId: AccountId?
        var secretTag: String?
        var options: [SecretSource] = []

        if let chain, chain.isEthereumBased {
            accountResponse = metaAccount.fetch(for: chain.accountRequest())

            guard let accountResponse else {
                throw ChainAccountFetchingError.accountNotExists
            }

            accountId = metaAccount.fetchChainAccountId(for: chain.accountRequest())
            secretTag = KeystoreTagV2.ethereumSecretKeyTagForMetaId(
                metaAccount.metaId,
                accountId: accountId
            )
        } else if let _ = metaAccount.ethereumAddress {
            secretTag = KeystoreTagV2.ethereumSecretKeyTagForMetaId(
                metaAccount.metaId,
                accountId: nil
            )
        }

        let derivationTag = KeystoreTagV2.ethereumDerivationTagForMetaId(
            metaAccount.metaId,
            accountId: accountId
        )
        let derivationPath = try derivationPath(for: derivationTag)

        if let secretTag, try keystore.checkKey(for: secretTag) {
            options.append(.keystore)
        }

        return .init(
            name: ChainType.ethereum.rawValue,
            availableOptions: options,
            derivationPath: derivationPath,
            cryptoType: MultiassetCryptoType.ethereumEcdsa
        )
    }

    func substrateExportData(
        for metaAccount: MetaAccountModel,
        chain: ChainModel?
    ) throws -> AdvancedExportChainData {
        var accountResponse: ChainAccountResponse?
        var accountId: AccountId?
        var options: [SecretSource] = []

        if let chain {
            accountResponse = metaAccount.fetch(for: chain.accountRequest())
            guard let accountResponse else {
                throw ChainAccountFetchingError.accountNotExists
            }

            accountId = metaAccount.fetchChainAccountId(for: chain.accountRequest())
        }

        let seedTag = KeystoreTagV2.substrateSeedTagForMetaId(
            metaAccount.metaId,
            accountId: accountId
        )
        let hasSeed = try keystore.checkKey(for: seedTag)

        if hasSeed || accountResponse?.cryptoType.supportsSeedFromSecretKey ?? false {
            options.append(.seed)
        }

        options.append(.keystore)

        let derivationTag = KeystoreTagV2.substrateDerivationTagForMetaId(
            metaAccount.metaId,
            accountId: accountId
        )

        return .init(
            name: chain?.name ?? ChainType.substrate.rawValue,
            availableOptions: options,
            derivationPath: try derivationPath(for: derivationTag),
            cryptoType: MultiassetCryptoType(rawValue: metaAccount.substrateCryptoType!)!
        )
    }

    func derivationPath(for tag: String) throws -> String? {
        guard let derivationPathData = try keystore.loadIfKeyExists(tag) else {
            return .none
        }

        return String(data: derivationPathData, encoding: .utf8)
    }
}

private extension AdvancedExportInteractor {
    enum ChainType: String {
        case substrate = "Polkadot"
        case ethereum = "Ethereum"
    }
}
