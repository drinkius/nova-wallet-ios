struct ReferendumsViewModel {
    let sections: [ReferendumsSection]
}

enum ReferendumsSection {
    case personalActivities([ReferendumPersonalActivity])
    case tinderGov(TinderGovBannerViewModel)
    case settings(isFilterOn: Bool)
    case active(LoadableViewModelState<String>, [ReferendumsCellViewModel])
    case completed(LoadableViewModelState<String>, [ReferendumsCellViewModel])
    case empty(ReferendumsEmptyModel)
}

enum ReferendumPersonalActivity {
    case locks(ReferendumsUnlocksViewModel)
    case delegations(ReferendumsDelegationViewModel)
}

struct TinderGovBannerViewModel {
    let title: String
    let description: String
    let referendumCounterText: String
}

struct ReferendumsCellViewModel: Hashable {
    static func == (lhs: ReferendumsCellViewModel, rhs: ReferendumsCellViewModel) -> Bool {
        lhs.referendumIndex == rhs.referendumIndex && lhs.viewModel.isLoading == rhs.viewModel.isLoading
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(referendumIndex)
    }

    var referendumIndex: ReferendumIdLocal
    var viewModel: LoadableViewModelState<ReferendumView.Model>
}

enum ReferendumsEmptyModel {
    case referendumsNotFound
    case filteredListEmpty
}
