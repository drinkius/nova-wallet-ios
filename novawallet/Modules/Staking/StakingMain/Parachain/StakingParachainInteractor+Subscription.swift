import Foundation

extension StakingParachainInteractor {
    func clearChainRemoteSubscription(for chainId: ChainModel.Id) {
        if let chainSubscriptionId = chainSubscriptionId {
            stakingAssetSubscriptionService.detachFromGlobalData(
                for: chainSubscriptionId,
                chainId: chainId,
                queue: nil,
                closure: nil
            )

            self.chainSubscriptionId = nil
        }
    }

    func setupChainRemoteSubscription() {
        guard let chainId = selectedChainAsset?.chain.chainId else {
            return
        }

        chainSubscriptionId = stakingAssetSubscriptionService.attachToGlobalData(
            for: chainId,
            queue: nil,
            closure: nil
        )
    }

    func clearAccountRemoteSubscription() {
        if
            let accountSubscriptionId = accountSubscriptionId,
            let chainId = selectedChainAsset?.chain.chainId,
            let accountId = selectedAccount?.chainAccount.accountId {
            stakingAccountSubscriptionService.detachFromAccountData(
                for: accountSubscriptionId,
                chainId: chainId,
                accountId: accountId,
                queue: nil,
                closure: nil
            )

            self.accountSubscriptionId = nil
        }
    }

    func setupAccountRemoteSubscription() {
        guard
            let chainId = selectedChainAsset?.chain.chainId,
            let accountId = selectedAccount?.chainAccount.accountId else {
            return
        }

        accountSubscriptionId = stakingAccountSubscriptionService.attachToAccountData(
            for: chainId,
            accountId: accountId,
            queue: nil,
            closure: nil
        )
    }

    func performPriceSubscription() {
        guard let chainAsset = selectedChainAsset else {
            presenter?.didReceiveError(PersistentValueSettingsError.missingValue)
            return
        }

        guard let priceId = chainAsset.asset.priceId else {
            presenter?.didReceivePrice(nil)
            return
        }

        priceProvider = subscribeToPrice(for: priceId)
    }

    func performAssetBalanceSubscription() {
        guard let chainAssetId = selectedChainAsset?.chainAssetId else {
            presenter?.didReceiveError(PersistentValueSettingsError.missingValue)
            return
        }

        guard let accountId = selectedAccount?.chainAccount.accountId else {
            presenter?.didReceiveError(ChainAccountFetchingError.accountNotExists)
            return
        }

        balanceProvider = subscribeToAssetBalanceProvider(
            for: accountId,
            chainId: chainAssetId.chainId,
            assetId: chainAssetId.assetId
        )
    }

    func performDelegatorSubscription() {
        guard let chainId = selectedChainAsset?.chain.chainId else {
            presenter?.didReceiveError(PersistentValueSettingsError.missingValue)
            return
        }

        guard let accountId = selectedAccount?.chainAccount.accountId else {
            presenter?.didReceiveError(ChainAccountFetchingError.accountNotExists)
            return
        }

        delegatorProvider = subscribeToDelegatorState(
            for: chainId,
            accountId: accountId
        )
    }

    func performScheduledRequestsSubscription() {
        guard let chainId = selectedChainAsset?.chain.chainId else {
            presenter?.didReceiveError(PersistentValueSettingsError.missingValue)
            return
        }

        guard let accountId = selectedAccount?.chainAccount.accountId else {
            presenter?.didReceiveError(ChainAccountFetchingError.accountNotExists)
            return
        }

        scheduledRequestsProvider = subscribeToScheduledRequests(
            for: chainId,
            accountId: accountId
        )
    }
}

extension StakingParachainInteractor: PriceLocalStorageSubscriber, PriceLocalSubscriptionHandler {
    func handlePrice(result: Result<PriceData?, Error>, priceId: AssetModel.PriceId) {
        if let chainAsset = selectedChainAsset, chainAsset.asset.priceId == priceId {
            switch result {
            case let .success(priceData):
                presenter?.didReceivePrice(priceData)
            case let .failure(error):
                presenter?.didReceiveError(error)
            }
        }
    }
}

extension StakingParachainInteractor: WalletLocalStorageSubscriber,
    WalletLocalSubscriptionHandler {
    func handleAssetBalance(
        result: Result<AssetBalance?, Error>,
        accountId: AccountId,
        chainId: ChainModel.Id,
        assetId: AssetModel.Id
    ) {
        guard
            chainId == selectedChainAsset?.chain.chainId,
            assetId == selectedChainAsset?.asset.assetId,
            accountId == selectedAccount?.chainAccount.accountId else {
            return
        }

        switch result {
        case let .success(balance):
            presenter?.didReceiveAssetBalance(balance)
        case let .failure(error):
            presenter?.didReceiveError(error)
        }
    }
}

extension StakingParachainInteractor: ParastakingLocalStorageSubscriber,
    ParastakingLocalStorageHandler {
    func handleParastakingDelegatorState(
        result: Result<ParachainStaking.Delegator?, Error>,
        for chainId: ChainModel.Id,
        accountId: AccountId
    ) {
        guard
            chainId == selectedChainAsset?.chain.chainId,
            selectedAccount?.chainAccount.accountId == accountId else {
            return
        }

        switch result {
        case let .success(delegator):
            presenter?.didReceiveDelegator(delegator)
        case let .failure(error):
            presenter?.didReceiveError(error)
        }
    }

    func handleParastakingScheduledRequests(
        result: Result<[ParachainStaking.ScheduledRequest]?, Error>,
        for chainId: ChainModel.Id,
        accountId: AccountId
    ) {
        guard
            chainId == selectedChainAsset?.chain.chainId,
            selectedAccount?.chainAccount.accountId == accountId else {
            return
        }

        switch result {
        case let .success(requests):
            presenter?.didReceiveScheduledRequests(requests)
        case let .failure(error):
            presenter?.didReceiveError(error)
        }
    }
}
