import Foundation

final class EvmOnChainTransferSetupInteractor: EvmOnChainTransferInteractor {}

extension EvmOnChainTransferSetupInteractor: OnChainTransferSetupInteractorInputProtocol {
    func change(feeAsset _: ChainAsset?) {}
}
