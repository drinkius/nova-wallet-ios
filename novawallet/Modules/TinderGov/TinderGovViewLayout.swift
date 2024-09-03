import UIKit
import SnapKit
import SoraUI

final class TinderGovViewLayout: UIView {
    let gradientBackgroundView: MultigradientView = .create { view in
        let gradient = GradientModel.tinderGovBackgroundGradient

        view.colors = gradient.colors
        view.locations = gradient.locations
        view.startPoint = gradient.startPoint
        view.endPoint = gradient.endPoint
    }

    let votingListWidget = VotingListWidget()

    let cardsStack = CardsZStack()

    let ayeButton: RoundedButton = {
        let button = RoundedButton()
        button.applyIconWithBackgroundStyle()
        button.roundedBackgroundView?.fillColor = R.color.colorButtonBackgroundApprove()!
        button.roundedBackgroundView?.highlightedFillColor = R.color.colorButtonBackgroundApprove()!
        button.roundedBackgroundView?.cornerRadius = Constants.bigButtonSize / 2
        button.imageWithTitleView?.iconImage = R.image.iconThumbsUpFilled()
        return button
    }()

    let abstainButton: RoundedButton = {
        let button = RoundedButton()
        button.applyIconWithBackgroundStyle()
        button.roundedBackgroundView?.fillColor = R.color.colorButtonBackgroundSecondary()!
        button.roundedBackgroundView?.highlightedFillColor = R.color.colorButtonBackgroundSecondary()!
        button.roundedBackgroundView?.cornerRadius = Constants.smallButtonSize / 2
        button.imageWithTitleView?.iconImage = R.image.iconAbstain()
        return button
    }()

    let nayButton: RoundedButton = {
        let button = RoundedButton()
        button.applyIconWithBackgroundStyle()
        button.roundedBackgroundView?.fillColor = R.color.colorButtonBackgroundReject()!
        button.roundedBackgroundView?.highlightedFillColor = R.color.colorButtonBackgroundReject()!
        button.roundedBackgroundView?.cornerRadius = Constants.bigButtonSize / 2
        button.imageWithTitleView?.iconImage = R.image.iconThumbsDownFilled()
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
        votingListWidget.bind(with: .empty(count: "0", title: "No votings"))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Setup

private extension TinderGovViewLayout {
    func setupLayout() {
        addSubview(gradientBackgroundView)
        gradientBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(votingListWidget)
        votingListWidget.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(16)
            make.centerX.equalToSuperview()
        }

        addSubview(abstainButton)
        abstainButton.snp.makeConstraints { make in
            make.size.equalTo(Constants.smallButtonSize)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide).inset(Constants.buttonsBottomInset)
        }

        addSubview(nayButton)
        nayButton.snp.makeConstraints { make in
            make.size.equalTo(Constants.bigButtonSize)
            make.leading.greaterThanOrEqualToSuperview().inset(UIConstants.horizontalInset)
            make.trailing.equalTo(abstainButton.snp.leading).offset(-40)
            make.centerY.equalTo(abstainButton.snp.centerY)
        }

        addSubview(ayeButton)
        ayeButton.snp.makeConstraints { make in
            make.size.equalTo(Constants.bigButtonSize)
            make.leading.equalTo(abstainButton.snp.trailing).offset(40)
            make.trailing.lessThanOrEqualToSuperview().inset(UIConstants.horizontalInset)
            make.centerY.equalTo(abstainButton.snp.centerY)
        }

        nayButton.roundedBackgroundView?.cornerRadius = Constants.bigButtonSize / 2
        ayeButton.roundedBackgroundView?.cornerRadius = Constants.bigButtonSize / 2

        addSubview(cardsStack)
        cardsStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.top.equalTo(votingListWidget.snp.bottom).offset(20)
            make.bottom.equalTo(nayButton.snp.top).offset(-54)
        }
    }
}

// MARK: Cards

extension TinderGovViewLayout {
    func addCard(
        model: VoteCardModel
    ) {
        cardsStack.addCard(
            model: model
        )
    }

    /// Should be called after adding batch of cards, to inform top card that it's presented and became top
    /// `cardsStack.notifyTopView` is called automatically on top card in stack after dismissal animation
    func finishedAddingCards() {
        cardsStack.notifyTopView()
    }
}

extension TinderGovViewLayout {
    enum Constants {
        static let bigButtonSize: CGFloat = 64
        static let smallButtonSize: CGFloat = 56
        static let buttonsBottomInset: CGFloat = 20
    }
}
