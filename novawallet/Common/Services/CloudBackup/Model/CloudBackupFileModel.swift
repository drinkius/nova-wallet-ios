import Foundation

extension CloudBackup {
    typealias WalletId = String

    struct PublicData: Codable, Equatable {
        let modifiedAt: UInt64
        let wallets: Set<WalletPublicInfo>
    }

    struct WalletPublicInfo: Codable, Equatable, Hashable {
        let walletId: WalletId
        let substratePublicKey: String?
        let substrateAccountId: String?
        let substrateCryptoType: CryptoType?
        let ethereumAddress: String?
        let ethereumPublicKey: String?
        let name: String
        let type: WalletType
        let chainAccounts: Set<ChainAccountInfo>
    }

    struct ChainAccountInfo: Codable, Equatable, Hashable {
        let chainId: String
        let publicKey: String
        let accountId: String
        let cryptoType: CryptoType?
    }

    enum CryptoType: String, Codable, Equatable {
        case sr25519 = "SR25519"
        case ed25519 = "ED25519"
        case ecdsa = "ECDSA"
    }

    enum WalletType: String, Codable, Equatable {
        case secrets = "SECRETS"
        case watchOnly = "WATCH_ONLY"
        case paritySigner = "PARITY_SIGNER"
        case ledger = "LEDGER"
        case polkadotVault = "POLKADOT_VAULT"
    }

    struct DecryptedFileModel {
        struct PrivateData: Codable, Equatable {
            let wallets: Set<WalletPrivateInfo>
        }

        struct WalletPrivateInfo: Codable, Equatable, Hashable {
            let walletId: CloudBackup.WalletId
            let entropy: String?
            let substrate: SubstrateSecrets?
            let ethereum: EthereumSecrets?
            let chainAccounts: ChainAccountSecrets?
            let additional: [String: String]
        }

        struct SubstrateSecrets: Codable, Equatable, Hashable {
            let seed: String?
            let keypair: KeypairSecrets
            let derivationPath: String?
        }

        struct EthereumSecrets: Codable, Equatable, Hashable {
            let keypair: KeypairSecrets
            let derivationPath: String?
        }

        struct ChainAccountSecrets: Codable, Equatable, Hashable {
            let accountId: String
            let entropy: String?
            let seed: String?
            let keypair: KeypairSecrets
        }

        struct KeypairSecrets: Codable, Equatable, Hashable {
            let publicKey: String
            let privateKey: String
            let nonce: String? // for SR25519
        }

        let publicData: CloudBackup.PublicData
        let privateDate: PrivateData
    }

    struct EncryptedFileModel: Codable {
        let publicData: CloudBackup.PublicData
        let privateData: String
    }
}
