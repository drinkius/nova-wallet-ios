import Foundation

final class ChangeTargetsSelectValidatorsStartWireframe: SelectValidatorsStartWireframe {
    private let state: ExistingBonding

    init(state: ExistingBonding) {
        self.state = state
    }

    override func proceedToCustomList(
        from view: ControllerBackedProtocol?,
        validators: [ElectedValidatorInfo],
        recommended: [ElectedValidatorInfo],
        maxTargets: Int
    ) {
        guard let nextView = CustomValidatorListViewFactory
            .createChangeTargetsView(
                for: validators,
                recommendedValidators: recommended,
                maxTargets: maxTargets,
                with: state
            ) else { return }

        view?.controller.navigationController?.pushViewController(
            nextView.controller,
            animated: true
        )
    }

    override func proceedToRecommendedList(
        from view: SelectValidatorsStartViewProtocol?,
        validators: [ElectedValidatorInfo],
        maxTargets: Int
    ) {
        let selectedValidators = validators.map {
            SelectedValidatorInfo(
                address: $0.address,
                identity: $0.identity,
                stakeInfo: ValidatorStakeInfo(
                    nominators: $0.nominators,
                    totalStake: $0.totalStake,
                    stakeReturn: $0.stakeReturn,
                    maxNominatorsRewarded: $0.maxNominatorsRewarded
                )
            )
        }

        guard let nextView = RecommendedValidatorListViewFactory.createChangeTargetsView(
            for: selectedValidators,
            maxTargets: maxTargets,
            with: state
        ) else {
            return
        }

        view?.controller.navigationController?.pushViewController(
            nextView.controller,
            animated: true
        )
    }
}