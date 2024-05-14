import Foundation
import BigInt

final class HybridStakingRecommendationMediator: BaseStakingRecommendationMediator {
    let directStakingMediator: RelaychainStakingRecommendationMediating
    let nominationPoolsMediator: RelaychainStakingRecommendationMediating
    let directStakingRestrictionsBuilder: RelaychainStakingRestrictionsBuilding
    let chainAsset: ChainAsset

    private var restrictions: RelaychainStakingRestrictions?

    private var validationFactory: StakingRecommendationValidationFactoryProtocol?

    init(
        chainAsset: ChainAsset,
        directStakingMediator: RelaychainStakingRecommendationMediating,
        nominationPoolsMediator: RelaychainStakingRecommendationMediating,
        directStakingRestrictionsBuilder: RelaychainStakingRestrictionsBuilding,
        logger: LoggerProtocol
    ) {
        self.chainAsset = chainAsset
        self.directStakingMediator = directStakingMediator
        self.nominationPoolsMediator = nominationPoolsMediator
        self.directStakingRestrictionsBuilder = directStakingRestrictionsBuilder

        super.init(logger: logger)
    }

    private func updateValidationFactory() {
        if let minRewardableStake = restrictions?.minRewardableStake {
            validationFactory = HybridStakingValidationFactory(
                directRewardableStake: minRewardableStake,
                chainAsset: chainAsset
            )
        } else {
            validationFactory = nil
        }
    }

    override func updateRecommendation(for amount: BigUInt) {
        guard let restrictions = restrictions else {
            return
        }

        if let minStake = restrictions.minRewardableStake, amount < minStake {
            directStakingMediator.delegate = nil
            nominationPoolsMediator.delegate = self

            nominationPoolsMediator.update(amount: amount)
        } else {
            directStakingMediator.delegate = self
            nominationPoolsMediator.delegate = nil

            directStakingMediator.update(amount: amount)
        }
    }

    override func performSetup() {
        directStakingMediator.startRecommending()
        nominationPoolsMediator.startRecommending()

        directStakingRestrictionsBuilder.delegate = self
        directStakingRestrictionsBuilder.start()
    }

    override func clearState() {
        super.clearState()

        directStakingMediator.delegate = nil
        directStakingMediator.stopRecommending()

        nominationPoolsMediator.delegate = nil
        nominationPoolsMediator.stopRecommending()

        directStakingRestrictionsBuilder.delegate = nil
        directStakingRestrictionsBuilder.stop()
    }
}

extension HybridStakingRecommendationMediator: RelaychainStakingRestrictionsBuilderDelegate {
    func restrictionsBuilder(
        _: RelaychainStakingRestrictionsBuilding,
        didPrepare restrictions: RelaychainStakingRestrictions
    ) {
        self.restrictions = restrictions

        updateValidationFactory()

        logger.debug("Restrictions: \(restrictions)")

        isReady = true
        updateRecommendationIfReady()
    }

    func restrictionsBuilder(_: RelaychainStakingRestrictionsBuilding, didReceive error: Error) {
        logger.debug("Restrictions error: \(error)")
        delegate?.didReceiveRecommendation(error: error)
    }
}

extension HybridStakingRecommendationMediator: RelaychainStakingRecommendationDelegate {
    func didReceive(recommendation: RelaychainStakingRecommendation, amount: BigUInt) {
        let factories = [
            recommendation.validationFactory,
            validationFactory
        ].compactMap { $0 }

        let hybridRecommendation = RelaychainStakingRecommendation(
            staking: recommendation.staking,
            restrictions: recommendation.restrictions,
            validationFactory: CombinedStakingValidationFactory(factories: factories)
        )

        logger.debug("Recommendation: \(hybridRecommendation)")

        delegate?.didReceive(recommendation: hybridRecommendation, amount: amount)
    }

    func didReceiveRecommendation(error: Error) {
        logger.error("Error: \(error)")
        delegate?.didReceiveRecommendation(error: error)
    }
}
