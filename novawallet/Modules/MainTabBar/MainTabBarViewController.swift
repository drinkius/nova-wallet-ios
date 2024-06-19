import UIKit

final class MainTabBarViewController: UITabBarController {
    var presenter: MainTabBarPresenterProtocol!

    private var viewAppeared: Bool = false

    // Status message label
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Syncing..."
        label.textAlignment = .center
        label.backgroundColor = UIColor.red
        label.textColor = .white
        label.isHidden = true
        return label
    }()

    var isSyncing: Bool = false {
        didSet {
            updateStatusLabel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        configureTabBar()

        setupStatusLabel()
    }

    private func setupStatusLabel() {
        view.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.trailing.leading.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(30)
        }
    }

    private func updateStatusLabel() {
        statusLabel.isHidden = !isSyncing
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !viewAppeared {
            viewAppeared = true
            presenter.setup()
        }

        presenter.viewDidAppear()
    }

    private func configureTabBar() {
        let appearance = UITabBarAppearance()

        appearance.shadowImage = UIImage()

        let normalAttributes = [
            NSAttributedString.Key.foregroundColor: R.color.colorIconNavbarInactive()!,
            NSAttributedString.Key.font: UIFont.caption2
        ]
        let selectedAttributes = [
            NSAttributedString.Key.foregroundColor: R.color.colorIconAccent()!,
            NSAttributedString.Key.font: UIFont.caption2
        ]

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        appearance.backgroundEffect = UIBlurEffect(style: .dark)

        tabBar.standardAppearance = appearance

        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

extension MainTabBarViewController: UITabBarControllerDelegate {
    func tabBarController(
        _: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        if viewController == viewControllers?[selectedIndex],
           let scrollableController = viewController as? ScrollsToTop {
            scrollableController.scrollToTop()
        }

        return true
    }
}

extension MainTabBarViewController: MainTabBarViewProtocol {
    func didReplaceView(for newView: UIViewController, for index: Int) {
        guard var newViewControllers = viewControllers else {
            return
        }

        newViewControllers[index] = newView

        setViewControllers(newViewControllers, animated: false)
    }

    func setIsSyncing(_ isSyncing: Bool) {
        self.isSyncing = isSyncing
    }
}
