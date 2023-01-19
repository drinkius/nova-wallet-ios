import UIKit
import SnapKit
import SoraUI

final class DelegateBanner: UIView {
    let bannerView: GradientBannerView = .create {
        $0.infoView.imageView.image = R.image.iconDelegateBadges()
        $0.stackView.setCustomSpacing(16, after: $0.infoView)
        $0.bind(model: .stakingController())
    }

    let closeButton: RoundedButton = .create {
        $0.roundedBackgroundView?.shadowOpacity = 0
        $0.roundedBackgroundView?.fillColor = R.color.colorBlockBackground()!
        $0.roundedBackgroundView?.highlightedFillColor = R.color.colorBlockBackground()!
        $0.roundedBackgroundView?.strokeColor = .clear
        $0.roundedBackgroundView?.highlightedStrokeColor = .clear
        $0.roundedBackgroundView?.cornerRadius = 12
        $0.contentInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        $0.imageWithTitleView?.iconImage = R.image.iconClose()?.tinted(with: R.color.colorIconChip()!)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(bannerView)
        bannerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        addSubview(closeButton)
        closeButton.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 24, height: 24))
            $0.trailing.equalToSuperview().inset(8)
            $0.top.equalToSuperview().inset(12)
        }
    }

    func set(locale _: Locale) {
        bannerView.infoView.titleLabel.text = "Are you a Delegate?"
        bannerView.infoView.subtitleLabel.text = "Tell us more about yourself so Nova users get to know you better"
        bannerView.linkButton?.imageWithTitleView?.title = "Describe yourself"
        bannerView.contentInsets = .init(top: 16, left: 16, bottom: 20, right: 0)
    }
}
