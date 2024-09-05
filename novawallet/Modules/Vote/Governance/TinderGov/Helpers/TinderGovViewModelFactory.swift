import Foundation

protocol TinderGovViewModelFactoryProtocol {
    func createTinderGovReferendumsSection(
        using filter: TinderGovReferendumsFilter,
        locale: Locale
    ) -> ReferendumsSection?

    func createVotingListViewModel(
        from votingList: [ReferendumIdLocal],
        locale: Locale
    ) -> VotingListWidgetViewModel

    func createReferendumsCounterViewModel(
        currentReferendumId: ReferendumIdLocal,
        referendums: [ReferendumLocal],
        locale: Locale
    ) -> String?
}

struct TinderGovViewModelFactory: TinderGovViewModelFactoryProtocol {
    func createTinderGovReferendumsSection(
        using filter: TinderGovReferendumsFilter,
        locale: Locale
    ) -> ReferendumsSection? {
        let tinderGovReferenda = filter()

        let section: ReferendumsSection? = {
            guard !tinderGovReferenda.isEmpty else {
                return nil
            }

            return .tinderGov(
                TinderGovBannerViewModel(
                    title: R.string.localizable.commonTinderGov(preferredLanguages: locale.rLanguages),
                    description: R.string.localizable.tinderGovBannerMessage(
                        preferredLanguages: locale.rLanguages
                    ),
                    referendumCounterText: R.string.localizable.commonCountedReferenda(
                        tinderGovReferenda.count,
                        preferredLanguages: locale.rLanguages
                    )
                )
            )
        }()

        return section
    }

    func createVotingListViewModel(
        from votingList: [ReferendumIdLocal],
        locale: Locale
    ) -> VotingListWidgetViewModel {
        let languages = locale.rLanguages

        return if votingList.isEmpty {
            VotingListWidgetViewModel.empty(
                count: "\(votingList.count)",
                title: R.string.localizable.votingListWidgetTitleEmpty(preferredLanguages: languages)
            )
        } else {
            VotingListWidgetViewModel.votings(
                count: "\(votingList.count)",
                title: R.string.localizable.votingListWidgetTitle(preferredLanguages: languages)
            )
        }
    }

    func createReferendumsCounterViewModel(
        currentReferendumId: ReferendumIdLocal,
        referendums: [ReferendumLocal],
        locale: Locale
    ) -> String? {
        guard let currentIndex = referendums.firstIndex(where: { $0.index == currentReferendumId }) else {
            return nil
        }

        let currentNumber = referendums.count - currentIndex

        let counterString = R.string.localizable.commonCounter(
            currentNumber,
            referendums.count,
            preferredLanguages: locale.rLanguages
        )

        return counterString
    }
}