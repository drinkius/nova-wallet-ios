import Foundation
import BigInt
import SoraFoundation

final class ProxySignValidationPresenter {
    let view: ControllerBackedProtocol
    let wireframe: ProxySignValidationWireframeProtocol
    let interactor: ProxySignValidationInteractorInputProtocol

    let dataValidationFactory: BaseDataValidatingFactoryProtocol
    let chainAsset: ChainAsset
    let localizationManager: LocalizationManagerProtocol
    let logger: LoggerProtocol
    let completionClosure: ProxySignValidationCompletion
    
    let balance: AssetBalance?
    let fee: ExtrinsicFeeProtocol?
    let minBalance: BigUInt?
    
    init(
        view: ControllerBackedProtocol,
        interactor: ProxySignValidationInteractorInputProtocol,
        wireframe: ProxySignValidationWireframeProtocol,
        dataValidationFactory: BaseDataValidatingFactoryProtocol,
        chainAsset: ChainAsset,
        completionClosure: ProxySignValidationCompletion,
        localizationManager: LocalizationManagerProtocol,
        logger: LoggerProtocol
    ) {
        self.view = view
        self.interactor = interactor
        self.wireframe = wireframe
        self.dataValidationFactory = dataValidationFactory
        self.chainAsset = chainAsset
        self.completionClosure = completionClosure
        self.localizationManager = localizationManager
        self.logger = logger
    }
    
    private func completeValidation() {
        guard let balance = balance, let fee = fee, let minBalance = minBalance else {
            return
        }
        
        let locale = localizationManager.selectedLocale
        
        DataValidationRunner(validators: [
            dataValidationFactory.canPayFeeInPlank(
                balance: balance.transferable,
                fee: fee,
                asset: chainAsset.assetDisplayInfo,
                locale: locale
            ),
            dataValidationFactory.notViolatingMinBalancePaying(
                fee: fee,
                total: balance.balanceCountingEd,
                minBalance: minBalance,
                locale: locale
            )
        ]).runValidation(
            notifyingOnSuccess: { [weak self] in
                self?.completionClosure(true)
            },
            notifyingOnStop: { problem in
                switch problem {
                case .error, .warning:
                    self?.completionClosure(false)
                case .asyncProcess:
                    break
                }
            },
            notifyingOnResume: nil
        )
        
        
    }
}

extension ProxySignValidationPresenter: ProxySignValidationPresenterProtocol {
    func setup() {
        interactor.setup()
    }
}

extension ProxySignValidationPresenter: ProxySignValidationInteractorOutputProtocol {
    func didReceiveBalance(_ balance: AssetBalance) {
        logger.debug("Did receive balance: \(balance)")
        
        self.balance = balance
        
        completeValidation()
    }
    
    func didReceiveMinBalance(_ minBalance: BigUInt) {
        logger.debug("Did receive min balance: \(minBalance)")
        
        self.minBalance = minBalance
        
        completeValidation()
    }
    
    func didReceiveFee(_ fee: ExtrinsicFeeProtocol) {
        logger.debug("Did receive fee: \(fee)")
        
        self.fee = fee
        
        completeValidation()
    }
    
    func didReceiveError(_ error: Error) {
        logger.error("Did receive error: \(error)")
        
        let locale = localizationManager.selectedLocale
        
        if !wireframe.present(error: error, from: view, locale: locale) {
            _ = wireframe.present(error: CommonError.undefined, from: view, locale: locale)
        }
    }
}
