import Foundation
import BigInt

struct StakingStateCommonData {
    let address: String?
    let chain: Chain?
    let accountInfo: AccountInfo?
    let price: PriceData?
    let calculatorEngine: RewardCalculatorEngineProtocol?
    let electionStatus: ElectionStatus?
    let eraStakersInfo: EraStakersInfo?
    let minimalStake: BigUInt?
    let maxNominatorsPerValidator: UInt32?
}

extension StakingStateCommonData {
    static var empty: StakingStateCommonData {
        StakingStateCommonData(
            address: nil,
            chain: nil,
            accountInfo: nil,
            price: nil,
            calculatorEngine: nil,
            electionStatus: nil,
            eraStakersInfo: nil,
            minimalStake: nil,
            maxNominatorsPerValidator: nil
        )
    }

    func byReplacing(address: String?) -> StakingStateCommonData {
        StakingStateCommonData(
            address: address,
            chain: chain,
            accountInfo: accountInfo,
            price: price,
            calculatorEngine: calculatorEngine,
            electionStatus: electionStatus,
            eraStakersInfo: eraStakersInfo,
            minimalStake: minimalStake,
            maxNominatorsPerValidator: maxNominatorsPerValidator
        )
    }

    func byReplacing(chain: Chain?) -> StakingStateCommonData {
        StakingStateCommonData(
            address: address,
            chain: chain,
            accountInfo: accountInfo,
            price: price,
            calculatorEngine: calculatorEngine,
            electionStatus: electionStatus,
            eraStakersInfo: eraStakersInfo,
            minimalStake: minimalStake,
            maxNominatorsPerValidator: maxNominatorsPerValidator
        )
    }

    func byReplacing(accountInfo: AccountInfo?) -> StakingStateCommonData {
        StakingStateCommonData(
            address: address,
            chain: chain,
            accountInfo: accountInfo,
            price: price,
            calculatorEngine: calculatorEngine,
            electionStatus: electionStatus,
            eraStakersInfo: eraStakersInfo,
            minimalStake: minimalStake,
            maxNominatorsPerValidator: maxNominatorsPerValidator
        )
    }

    func byReplacing(price: PriceData?) -> StakingStateCommonData {
        StakingStateCommonData(
            address: address,
            chain: chain,
            accountInfo: accountInfo,
            price: price,
            calculatorEngine: calculatorEngine,
            electionStatus: electionStatus,
            eraStakersInfo: eraStakersInfo,
            minimalStake: minimalStake,
            maxNominatorsPerValidator: maxNominatorsPerValidator
        )
    }

    func byReplacing(calculatorEngine: RewardCalculatorEngineProtocol?) -> StakingStateCommonData {
        StakingStateCommonData(
            address: address,
            chain: chain,
            accountInfo: accountInfo,
            price: price,
            calculatorEngine: calculatorEngine,
            electionStatus: electionStatus,
            eraStakersInfo: eraStakersInfo,
            minimalStake: minimalStake,
            maxNominatorsPerValidator: maxNominatorsPerValidator
        )
    }

    func byReplacing(electionStatus: ElectionStatus?) -> StakingStateCommonData {
        StakingStateCommonData(
            address: address,
            chain: chain,
            accountInfo: accountInfo,
            price: price,
            calculatorEngine: calculatorEngine,
            electionStatus: electionStatus,
            eraStakersInfo: eraStakersInfo,
            minimalStake: minimalStake,
            maxNominatorsPerValidator: maxNominatorsPerValidator
        )
    }

    func byReplacing(eraStakersInfo: EraStakersInfo?) -> StakingStateCommonData {
        StakingStateCommonData(
            address: address,
            chain: chain,
            accountInfo: accountInfo,
            price: price,
            calculatorEngine: calculatorEngine,
            electionStatus: electionStatus,
            eraStakersInfo: eraStakersInfo,
            minimalStake: minimalStake,
            maxNominatorsPerValidator: maxNominatorsPerValidator
        )
    }

    func byReplacing(minimalStake: BigUInt?) -> StakingStateCommonData {
        StakingStateCommonData(
            address: address,
            chain: chain,
            accountInfo: accountInfo,
            price: price,
            calculatorEngine: calculatorEngine,
            electionStatus: electionStatus,
            eraStakersInfo: eraStakersInfo,
            minimalStake: minimalStake,
            maxNominatorsPerValidator: maxNominatorsPerValidator
        )
    }

    func byReplacing(maxNominatorsPerValidator: UInt32?) -> StakingStateCommonData {
        StakingStateCommonData(
            address: address,
            chain: chain,
            accountInfo: accountInfo,
            price: price,
            calculatorEngine: calculatorEngine,
            electionStatus: electionStatus,
            eraStakersInfo: eraStakersInfo,
            minimalStake: minimalStake,
            maxNominatorsPerValidator: maxNominatorsPerValidator
        )
    }
}
